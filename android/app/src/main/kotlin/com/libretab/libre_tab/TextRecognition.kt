package com.libretab.libre_tab

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Reads the words in a photo with Tesseract, on the device, for camera
 * import (lib/core/ocr/text_recognizer.dart). Each word comes back with its
 * box in pixels of the upright image; lib/core/ocr/ocr_layout.dart lines
 * chords up with the lyrics from those boxes. The iOS side does the same
 * with Apple Vision (ios/Runner/AppDelegate.swift).
 */
class TextRecognition(private val context: Context, messenger: BinaryMessenger) {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, "libre_tab/text_recognition").setMethodCallHandler { call, result ->
            val path = call.argument<String>("path")
            if (call.method != "recognize" || path == null) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            worker.execute {
                try {
                    val words = recognize(path)
                    main.post { result.success(words) }
                } catch (e: Exception) {
                    main.post { result.error("unreadable", e.message, null) }
                }
            }
        }
    }

    private fun recognize(path: String): List<Map<String, Any>> {
        val image = uprightImage(path) ?: throw IllegalArgumentException("Not an image")
        val tess = TessBaseAPI()
        try {
            check(tess.init(dataDir().absolutePath, "eng+spa")) { "Tesseract didn't start" }
            // Sparse text: find every bit of text in no particular order,
            // so lone chords over a word aren't skipped. Lines are rebuilt
            // from the boxes in Dart.
            tess.pageSegMode = TessBaseAPI.PageSegMode.PSM_SPARSE_TEXT
            tess.setImage(image)
            tess.getUTF8Text() // runs recognition
            val words = mutableListOf<Map<String, Any>>()
            val iterator = tess.resultIterator ?: return words
            val level = TessBaseAPI.PageIteratorLevel.RIL_WORD
            iterator.begin()
            do {
                val text = iterator.getUTF8Text(level)?.trim().orEmpty()
                if (text.isEmpty() || iterator.confidence(level) < MIN_CONFIDENCE) continue
                val box = iterator.getBoundingRect(level)
                words += mapOf(
                    "text" to text,
                    "left" to box.left.toDouble(),
                    "top" to box.top.toDouble(),
                    "right" to box.right.toDouble(),
                    "bottom" to box.bottom.toDouble(),
                )
            } while (iterator.next(level))
            iterator.delete()
            return words
        } finally {
            tess.recycle()
            image.recycle()
        }
    }

    /** The photo, scaled to at most [MAX_SIDE] and turned upright. */
    private fun uprightImage(path: String): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= MAX_SIDE) sample *= 2
        val bitmap = BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            },
        ) ?: return null
        val degrees = when (
            ExifInterface(path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL,
            )
        ) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> return bitmap
        }
        val turned = Bitmap.createBitmap(
            bitmap, 0, 0, bitmap.width, bitmap.height,
            Matrix().apply { postRotate(degrees) }, true,
        )
        if (turned != bitmap) bitmap.recycle()
        return turned
    }

    /**
     * Tesseract reads its language models from files, so the bundled ones
     * (assets/tessdata) are copied out once. Returns the folder holding
     * `tessdata/`.
     */
    private fun dataDir(): File {
        val root = File(context.filesDir, "tesseract")
        val tessdata = File(root, "tessdata").apply { mkdirs() }
        for (name in context.assets.list("tessdata").orEmpty()) {
            val target = File(tessdata, name)
            if (target.exists() && target.length() > 0) continue
            val partial = File(tessdata, "$name.part")
            context.assets.open("tessdata/$name").use { input ->
                partial.outputStream().use { input.copyTo(it) }
            }
            partial.renameTo(target)
        }
        return root
    }

    private companion object {
        const val MAX_SIDE = 3000
        /** Below this Tesseract is mostly guessing at smudges. */
        const val MIN_CONFIDENCE = 30f
    }
}
