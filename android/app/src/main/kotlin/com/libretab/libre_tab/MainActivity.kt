package com.libretab.libre_tab

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Song files other apps hand to Libre Tab: "Open with" (ACTION_VIEW) and
 * "Share to" (ACTION_SEND), declared in AndroidManifest.xml. Files are
 * queued and Dart collects them (lib/core/files/incoming_files.dart), so one
 * that arrives while Flutter is still starting isn't lost.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private val pending = mutableListOf<Map<String, Any>>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        TextRecognition(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "libre_tab/incoming_files",
        ).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "takePending") {
                    result.success(pending.toList())
                    pending.clear()
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Not again after a rotation: the file was already taken.
        if (savedInstanceState == null) receive(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        receive(intent)
    }

    private fun receive(intent: Intent?) {
        val file = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data?.let(::read)
            Intent.ACTION_SEND -> streamOf(intent)?.let(::read)
                ?: intent.getStringExtra(Intent.EXTRA_TEXT)?.let {
                    // Text shared from a page: treat it like a .txt file.
                    val bytes = it.toByteArray()
                    if (bytes.size > MAX_BYTES) null
                    else mapOf("name" to "shared.txt", "bytes" to bytes)
                }
            else -> null
        } ?: return
        pending.add(file)
        channel?.invokeMethod("filesAvailable", null)
    }

    private fun streamOf(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun read(uri: Uri): Map<String, Any>? {
        // Only files another app shares through a content provider. A
        // file:// path could point at Libre Tab's own private files (its
        // database), which must not be opened on another app's say-so.
        if (uri.scheme != "content") return null
        return try {
            val bytes = contentResolver.openInputStream(uri)?.use { input ->
                // Read at most one byte past the limit, never the whole file.
                val data = input.readNBytesCompat(MAX_BYTES + 1)
                if (data.size > MAX_BYTES) null else data
            }
            bytes?.let { mapOf("name" to nameOf(uri), "bytes" to it) }
        } catch (e: Exception) {
            // Unreadable (permission gone, file deleted): nothing to open.
            null
        }
    }

    /** Up to [limit] bytes from the stream (InputStream.readNBytes is API 33+). */
    private fun java.io.InputStream.readNBytesCompat(limit: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(16 * 1024)
        while (out.size() < limit) {
            val read = read(buffer, 0, minOf(buffer.size, limit - out.size()))
            if (read < 0) break
            out.write(buffer, 0, read)
        }
        return out.toByteArray()
    }

    /** The file's name, with ".txt" added to plain text that has none. */
    private fun nameOf(uri: Uri): String {
        var name = contentResolver.query(
            uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        } ?: uri.lastPathSegment ?: "song"
        val type = contentResolver.getType(uri)
        if ('.' !in name && type?.startsWith("text/") == true) name += ".txt"
        return name
    }

    private companion object {
        /** Bigger than any song; stops a wrong file from filling memory. */
        const val MAX_BYTES = 5_000_000
    }
}
