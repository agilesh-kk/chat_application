package com.axisstudio.memento

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.axisstudio.memento/content_reader"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "readContentUri") {
                val uri = call.argument<String>("uri")
                if (uri != null) {
                    try {
                        val inputStream = contentResolver.openInputStream(Uri.parse(uri))
                        if (inputStream != null) {
                            val bytes = inputStream.readBytes()
                            result.success(bytes)
                        } else {
                            result.error("READ_ERROR", "Unable to open input stream for URI", null)
                        }
                    } catch (e: Exception) {
                        result.error("READ_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_URI", "URI is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
