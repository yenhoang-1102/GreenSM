package com.example.ride_booking_app

import android.content.Intent
import android.os.Build
import com.clevertap.android.sdk.CleverTapAPI
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            CleverTapAPI.getDefaultInstance(this)
                ?.pushNotificationClickedEvent(intent.extras)
        }
    }
}
