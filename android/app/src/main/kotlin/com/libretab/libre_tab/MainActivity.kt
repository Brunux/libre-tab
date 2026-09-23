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
                    mapOf("name" to "shared.txt", "bytes" to it.toByteArray())
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

    private fun read(uri: Uri): Map<String, Any>? = try {
        val bytes = contentResolver.openInputStream(uri)?.use { input ->
            val data = input.readBytes()
            if (data.size > MAX_BYTES) null else data
        }
        bytes?.let { mapOf("name" to nameOf(uri), "bytes" to it) }
    } catch (e: Exception) {
        // Unreadable (permission gone, file deleted): nothing to open.
        null
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
