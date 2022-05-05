package com.olaf.weight_tracker

import android.content.Intent
import android.os.Bundle
import com.google.android.gms.actions.NoteIntents
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private var savedNote: String? = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(FlutterEngine(this))
        val intent = intent
        val action = intent.action
        val type = intent.type
        if (NoteIntents.ACTION_CREATE_NOTE == action && type != null) {
            if ("text/plain" == type) {
                handleSendText(intent)
            }
        }
        MethodChannel(getFlutterEngine()?.getDartExecutor()?.getBinaryMessenger(), "app.channel.shared.data")
            .setMethodCallHandler { methodCall, result ->
                if (methodCall.method.contentEquals("getSavedNote")) {
                    result.success(savedNote)
                    savedNote = null
                }
            }
    }


    fun handleSendText(intent: Intent) {
        savedNote = intent.getStringExtra(Intent.EXTRA_TEXT)
    }
}
