package com.example.flashcard_app

import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private var tts: TextToSpeech? = null

    // Phát âm nội dung thẻ bằng TextToSpeech có sẵn của Android (không cần thư viện ngoài)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flashcard_app/speech")
            .setMethodCallHandler { call, result ->
                if (call.method != "speak") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = call.argument<String>("text") ?: ""
                val language = call.argument<String>("language") ?: "en-US"
                val speak = { engine: TextToSpeech ->
                    engine.language = Locale.forLanguageTag(language)
                    engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "flashcard")
                }
                val ready = tts
                if (ready != null) {
                    speak(ready)
                    result.success(true)
                } else {
                    tts = TextToSpeech(this) { status ->
                        val engine = tts
                        if (status == TextToSpeech.SUCCESS && engine != null) {
                            speak(engine)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                }
            }
    }

    override fun onDestroy() {
        tts?.shutdown()
        super.onDestroy()
    }
}
