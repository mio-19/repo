package app.grapheneos.camera.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import app.grapheneos.camera.ui.activities.MainActivity

/**
 * Manifest-registered broadcast receiver for remote smartwatch camera events.
 * Listens for generic AppBridge notifications forwarded by Bluetooth LE companion
 * services without requiring hardcoded camera logic in companion applications.
 */
class RemoteCameraReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "RemoteCameraReceiver"
        const val WATCH_APP_CAMERA = "org.asteroidos.camera"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        val appId = intent.getStringExtra("extra_app_id")
        if (appId != WATCH_APP_CAMERA) return

        val action = intent.getStringExtra("extra_action") ?: return
        Log.i(TAG, "Watch camera intent received: action=$action")

        if (action == "launch" || action == "open" || action == "capture") {
            try {
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra("extra_remote_action", action)
                }
                context.startActivity(launchIntent)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to launch Camera activity", e)
            }
        }
    }
}
