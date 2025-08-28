package com.example.sms_forwarder_new

import android.Manifest
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.sms_forwarder_new.SmsReceiver

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sms_forwarder/sms"
    private val REQUEST_PERMISSIONS = 123
    private val REQUEST_DEFAULT_SMS = 124
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Set up the method channel for SmsReceiver
        SmsReceiver.methodChannel = methodChannel
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    requestSmsPermissions()
                    result.success(true)
                }
                "checkPermissions" -> {
                    val hasPermissions = checkSmsPermissions()
                    result.success(hasPermissions)
                }
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    
                    if (phoneNumber != null && message != null) {
                        sendSms(phoneNumber, message, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone number and message are required", null)
                    }
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(null)
                }
                "initializeSmsReceiver" -> {
                    val status = initializeSmsReceiver()
                    result.success(status)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun checkSmsPermissions(): Boolean {
        val smsPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS)
        val sendSmsPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
        val readSmsPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS)
        
        return smsPermission == PackageManager.PERMISSION_GRANTED &&
               sendSmsPermission == PackageManager.PERMISSION_GRANTED &&
               readSmsPermission == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestSmsPermissions() {
        val permissions = arrayOf(
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.SEND_SMS,
            Manifest.permission.READ_SMS
        )
        
        ActivityCompat.requestPermissions(this, permissions, REQUEST_PERMISSIONS)
    }
    
    private fun sendSms(phoneNumber: String, message: String, result: MethodChannel.Result) {
        try {
            if (!checkSmsPermissions()) {
                result.error("PERMISSION_DENIED", "SMS permissions not granted", null)
                return
            }
            
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            result.success("SMS sent successfully")
        } catch (e: Exception) {
            result.error("SMS_ERROR", "Failed to send SMS: ${e.message}", null)
        }
    }
    
    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.fromParts("package", packageName, null)
        startActivity(intent)
    }
    
    private fun initializeSmsReceiver(): String {
        return if (checkSmsPermissions()) {
            "SMS Receiver initialized with permissions"
        } else {
            "SMS Receiver initialized but missing permissions"
        }
    }
}
