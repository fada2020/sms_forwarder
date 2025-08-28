package com.example.sms_forwarder_new

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsMessage
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class SmsReceiver : BroadcastReceiver() {
    companion object {
        const val SMS_RECEIVED_ACTION = "android.provider.Telephony.SMS_RECEIVED"
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == SMS_RECEIVED_ACTION) {
            val bundle = intent.extras
            if (bundle != null) {
                val pdus = bundle.get("pdus") as Array<*>?
                val format = bundle.getString("format")
                
                pdus?.let { pduArray ->
                    for (pdu in pduArray) {
                        val smsMessage = SmsMessage.createFromPdu(pdu as ByteArray, format)
                        val sender = smsMessage.displayOriginatingAddress
                        val messageBody = smsMessage.messageBody
                        
                        // Flutter로 SMS 데이터 전송
                        val smsData = mapOf(
                            "sender" to sender,
                            "message" to messageBody,
                            "timestamp" to System.currentTimeMillis()
                        )
                        
                        methodChannel?.invokeMethod("onSmsReceived", smsData)
                    }
                }
            }
        }
    }
}