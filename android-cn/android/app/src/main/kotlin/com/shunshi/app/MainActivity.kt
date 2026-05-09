package com.shunshi.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shunshi.app/voice"
    private val VOICE_REQUEST_CODE = 1001
    private var voiceResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    voiceResult = result
                    val locale = call.argument<String>("locale") ?: "zh_CN"
                    startVoiceInput(locale)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVoiceInput(locale: String) {
        try {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
                putExtra(RecognizerIntent.EXTRA_PROMPT, "请说话...")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }
            startActivityForResult(intent, VOICE_REQUEST_CODE)
        } catch (e: Exception) {
            voiceResult?.success(mapOf("error" to "语音识别不可用: ${e.localizedMessage}"))
            voiceResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == VOICE_REQUEST_CODE) {
            val result = voiceResult ?: return
            voiceResult = null

            if (resultCode == Activity.RESULT_OK && data != null) {
                val matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val text = matches?.firstOrNull() ?: ""
                result.success(mapOf("text" to text))
            } else if (resultCode == Activity.RESULT_CANCELED) {
                result.success(mapOf("text" to "", "error" to "用户取消"))
            } else {
                result.success(mapOf("error" to "识别失败(resultCode=$resultCode)"))
            }
        }
    }
}
