package com.example.study_pomodoro_record

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "study_pomodoro_record/share"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareFiles" -> shareFiles(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun shareFiles(call: MethodCall, result: MethodChannel.Result) {
        val rawPaths = call.argument<List<String>>("paths")
        val text = call.argument<String>("text")
        val subject = call.argument<String>("subject")

        if (rawPaths.isNullOrEmpty()) {
            result.error("invalid_args", "paths 不能为空", null)
            return
        }

        val uris = rawPaths.map { path ->
            val file = File(path)
            if (!file.exists()) {
                result.error("file_not_found", "文件不存在: $path", null)
                return
            }
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
        }

        val shareIntent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                type = "text/csv"
                putExtra(Intent.EXTRA_STREAM, uris.first())
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "text/csv"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
            }
        }

        if (!text.isNullOrBlank()) {
            shareIntent.putExtra(Intent.EXTRA_TEXT, text)
        }
        if (!subject.isNullOrBlank()) {
            shareIntent.putExtra(Intent.EXTRA_SUBJECT, subject)
        }
        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        startActivity(Intent.createChooser(shareIntent, "分享 CSV 文件"))
        result.success(null)
    }
}
