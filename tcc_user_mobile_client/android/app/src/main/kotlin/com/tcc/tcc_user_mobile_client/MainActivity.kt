package com.tcc.tcc_user_mobile_client

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle deep link on app launch
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle deep link when app is already running
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri = intent.data
            if (uri != null && uri.scheme == "tccapp" && uri.host == "stripe-redirect") {
                // Stripe will automatically handle the redirect
                // The Flutter Stripe plugin listens for this intent
            }
        }
    }
}
