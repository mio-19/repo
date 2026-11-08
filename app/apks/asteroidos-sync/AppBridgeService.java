/*
 * AsteroidOSSync
 * Copyright (c) 2026 AsteroidOS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

package org.asteroidos.sync.connectivity;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Process;
import android.util.Log;

import androidx.core.app.NotificationCompat;
import androidx.core.app.RemoteInput;

import org.asteroidos.sync.asteroid.IAsteroidDevice;
import org.asteroidos.sync.utils.AsteroidUUIDS;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * AppBridge connectivity service for AsteroidOS: a BLE tunnel for remote control
 * and remote text input between the smartwatch and Android companion apps.
 *
 * Wire format: [0xA0][appIdLen:1B][appId][actionLen:1B][action][payload].
 * Compact app IDs:
 *  - "cam" -> "org.asteroidos.camera"
 *  - "kbd" -> "org.asteroidos.keyboard"
 */
public class AppBridgeService implements IConnectivityService {
    public static final String TAG = "AppBridgeService";

    public static final String PERMISSION_APP_BRIDGE = "org.asteroidos.sync.permission.APP_BRIDGE";
    public static final String ACTION_RECEIVE_FROM_WATCH = "org.asteroidos.sync.ACTION_RECEIVE_FROM_WATCH";
    public static final String ACTION_SEND_TO_WATCH = "org.asteroidos.sync.ACTION_SEND_TO_WATCH";
    public static final String EXTRA_APP_ID = "extra_app_id";
    public static final String EXTRA_ACTION = "extra_action";
    public static final String EXTRA_PAYLOAD = "extra_payload";

    private static final String CAMERA_PACKAGE = "app.grapheneos.camera";
    private static final String CAMERA_APP_ID = "org.asteroidos.camera";
    private static final String CAMERA_WIRE_APP_ID = "cam";

    private static final String KEYBOARD_APP_ID = "org.asteroidos.keyboard";
    private static final String KEYBOARD_WIRE_APP_ID = "kbd";

    private static final int KEYBOARD_NOTIFICATION_ID = 0xA072;
    private static final String KEYBOARD_CHANNEL_ID = "asteroidos_keyboard_channel";
    private static final String ACTION_KEYBOARD_REPLY = "org.asteroidos.sync.KEYBOARD_INPUT_REPLY";
    private static final String EXTRA_KEYBOARD_TEXT = "extra_keyboard_text";

    private static final int MAX_PACKET = 512;

    private static final Set<String> WATCH_TO_PHONE_ACTIONS = new HashSet<>(Arrays.asList(
            "capture", "flip", "zoom_in", "zoom_out", "torch", "mode_photo", "mode_video",
            "status_query"));
    private static final Set<String> PHONE_TO_WATCH_ACTIONS = new HashSet<>(Arrays.asList(
            "ready", "paused", "photo_captured", "video_started", "video_stopped"));

    private final Context mCtx;
    private final IAsteroidDevice mDevice;
    private BroadcastReceiver mSendReceiver;
    private BroadcastReceiver mReplyReceiver;

    public AppBridgeService(Context ctx, IAsteroidDevice device) {
        this.mCtx = ctx;
        this.mDevice = device;

        device.registerCallback(AsteroidUUIDS.APP_BRIDGE_TX_CHAR, this::handleAppBridgeData);
        registerSendReceiver();
        registerReplyReceiver();
    }

    private synchronized void registerSendReceiver() {
        if (mSendReceiver != null) return;
        mSendReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                handleSendToWatchIntent(intent, this);
            }
        };
        IntentFilter filter = new IntentFilter(ACTION_SEND_TO_WATCH);

        // The broadcast permission restricts senders to holders of PERMISSION_APP_BRIDGE.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            mCtx.registerReceiver(mSendReceiver, filter, PERMISSION_APP_BRIDGE, null,
                    Context.RECEIVER_EXPORTED);
        } else {
            mCtx.registerReceiver(mSendReceiver, filter, PERMISSION_APP_BRIDGE, null);
        }
    }

    private synchronized void registerReplyReceiver() {
        if (mReplyReceiver != null) return;
        mReplyReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (intent == null || !ACTION_KEYBOARD_REPLY.equals(intent.getAction())) return;
                Bundle results = RemoteInput.getResultsFromIntent(intent);
                if (results != null) {
                    CharSequence text = results.getCharSequence(EXTRA_KEYBOARD_TEXT);
                    if (text != null && text.length() > 0) {
                        sendAppBridgeMessage(KEYBOARD_WIRE_APP_ID, "commit", text.toString());
                    }
                }
                cancelKeyboardInputNotification();
            }
        };
        IntentFilter filter = new IntentFilter(ACTION_KEYBOARD_REPLY);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            mCtx.registerReceiver(mReplyReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            mCtx.registerReceiver(mReplyReceiver, filter);
        }
    }

    private synchronized void unregisterSendReceiver() {
        if (mSendReceiver != null) {
            try {
                mCtx.unregisterReceiver(mSendReceiver);
            } catch (IllegalArgumentException e) {
                Log.w(TAG, "Failed to unregister send receiver", e);
            }
            mSendReceiver = null;
        }
    }

    private synchronized void unregisterReplyReceiver() {
        if (mReplyReceiver != null) {
            try {
                mCtx.unregisterReceiver(mReplyReceiver);
            } catch (IllegalArgumentException e) {
                Log.w(TAG, "Failed to unregister reply receiver", e);
            }
            mReplyReceiver = null;
        }
    }

    private boolean isSentFromCameraApp(BroadcastReceiver receiver) {
        if (Build.VERSION.SDK_INT < 34) return false;
        int sentFromUid = getSentFromUid(receiver);
        if (sentFromUid == Process.INVALID_UID) return false;
        try {
            return mCtx.getPackageManager().getPackageUid(CAMERA_PACKAGE, 0) == sentFromUid;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    private static int getSentFromUid(BroadcastReceiver receiver) {
        try {
            return (Integer) BroadcastReceiver.class.getMethod("getSentFromUid").invoke(receiver);
        } catch (ReflectiveOperationException | RuntimeException e) {
            return Process.INVALID_UID;
        }
    }

    private void showKeyboardInputNotification(String prompt) {
        NotificationManager nm = (NotificationManager) mCtx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    KEYBOARD_CHANNEL_ID,
                    "Smartwatch Keyboard",
                    NotificationManager.IMPORTANCE_HIGH
            );
            channel.setDescription("Direct text input for smartwatch keyboard");
            nm.createNotificationChannel(channel);
        }

        RemoteInput remoteInput = new RemoteInput.Builder(EXTRA_KEYBOARD_TEXT)
                .setLabel("Type on phone...")
                .build();

        Intent replyIntent = new Intent(ACTION_KEYBOARD_REPLY).setPackage(mCtx.getPackageName());
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags |= PendingIntent.FLAG_MUTABLE;
        }
        PendingIntent replyPendingIntent = PendingIntent.getBroadcast(mCtx, 0, replyIntent, flags);

        NotificationCompat.Action replyAction =
                new NotificationCompat.Action.Builder(
                        android.R.drawable.ic_menu_send,
                        "Send to Watch",
                        replyPendingIntent
                )
                .addRemoteInput(remoteInput)
                .build();

        int icon = mCtx.getApplicationInfo().icon != 0 ? mCtx.getApplicationInfo().icon : android.R.drawable.ic_input_add;
        String content = (prompt != null && !prompt.isEmpty()) ? prompt : "Enter text on phone to send to watch";

        Notification notification = new NotificationCompat.Builder(mCtx, KEYBOARD_CHANNEL_ID)
                .setSmallIcon(icon)
                .setContentTitle("Smartwatch Text Input")
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(Notification.DEFAULT_ALL)
                .setAutoCancel(true)
                .addAction(replyAction)
                .build();

        nm.notify(KEYBOARD_NOTIFICATION_ID, notification);
    }

    private void cancelKeyboardInputNotification() {
        NotificationManager nm = (NotificationManager) mCtx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) {
            nm.cancel(KEYBOARD_NOTIFICATION_ID);
        }
    }

    /**
     * Process incoming App Bridge frame from the AsteroidOS watch.
     */
    private void handleAppBridgeData(byte[] value) {
        if (value == null || value.length < 3 || value.length > MAX_PACKET) return;
        if ((value[0] & 0xFF) != 0xA0) {
            Log.w(TAG, "AppBridge: invalid magic byte 0x" + Integer.toHexString(value[0] & 0xFF));
            return;
        }
        int offset = 1;
        int appIdLen = value[offset++] & 0xFF;
        if (value.length < offset + appIdLen + 1) return;
        String appId = new String(value, offset, appIdLen, StandardCharsets.UTF_8);
        offset += appIdLen;

        int actionLen = value[offset++] & 0xFF;
        if (value.length < offset + actionLen) return;
        String action = new String(value, offset, actionLen, StandardCharsets.UTF_8);
        offset += actionLen;

        String payload = "";
        if (value.length > offset) {
            payload = new String(value, offset, value.length - offset, StandardCharsets.UTF_8);
        }

        if (KEYBOARD_WIRE_APP_ID.equals(appId)) {
            if ("request_input".equals(action) || "open".equals(action)) {
                showKeyboardInputNotification(payload);
            } else if ("close".equals(action)) {
                cancelKeyboardInputNotification();
            }
            return;
        }

        if (!CAMERA_WIRE_APP_ID.equals(appId) || !WATCH_TO_PHONE_ACTIONS.contains(action)) {
            Log.d(TAG, "AppBridge: ignoring frame for unsupported app or action");
            return;
        }

        Intent intent = new Intent(ACTION_RECEIVE_FROM_WATCH)
                .setPackage(CAMERA_PACKAGE)
                .putExtra(EXTRA_APP_ID, CAMERA_APP_ID)
                .putExtra(EXTRA_ACTION, action)
                .putExtra(EXTRA_PAYLOAD, payload);
        mCtx.sendBroadcast(intent, PERMISSION_APP_BRIDGE);
    }

    /** Handles status updates from the companion apps that are meant for the watch. */
    private void handleSendToWatchIntent(Intent intent, BroadcastReceiver receiver) {
        if (intent == null || !ACTION_SEND_TO_WATCH.equals(intent.getAction())) return;
        String appId = intent.getStringExtra(EXTRA_APP_ID);
        String action = intent.getStringExtra(EXTRA_ACTION);
        String payload = intent.getStringExtra(EXTRA_PAYLOAD);

        if (KEYBOARD_APP_ID.equals(appId)) {
            if (action != null) {
                sendAppBridgeMessage(KEYBOARD_WIRE_APP_ID, action, payload);
            }
            return;
        }

        if (!CAMERA_APP_ID.equals(appId)) return;
        if (!isSentFromCameraApp(receiver)) {
            Log.w(TAG, "AppBridge: dropping message not sent by " + CAMERA_PACKAGE);
            return;
        }
        if (action == null || !PHONE_TO_WATCH_ACTIONS.contains(action)) return;
        sendAppBridgeMessage(CAMERA_WIRE_APP_ID, action, payload);
    }

    private void sendAppBridgeMessage(String wireAppId, String action) {
        sendAppBridgeMessage(wireAppId, action, null);
    }

    private void sendAppBridgeMessage(String wireAppId, String action, String payload) {
        byte[] appIdBytes = wireAppId.getBytes(StandardCharsets.UTF_8);
        byte[] actionBytes = action.getBytes(StandardCharsets.UTF_8);
        byte[] payloadBytes = payload != null ? payload.getBytes(StandardCharsets.UTF_8) : new byte[0];
        byte[] packet = new byte[3 + appIdBytes.length + actionBytes.length + payloadBytes.length];
        int idx = 0;
        packet[idx++] = (byte) 0xA0;
        packet[idx++] = (byte) appIdBytes.length;
        System.arraycopy(appIdBytes, 0, packet, idx, appIdBytes.length);
        idx += appIdBytes.length;
        packet[idx++] = (byte) actionBytes.length;
        System.arraycopy(actionBytes, 0, packet, idx, actionBytes.length);
        idx += actionBytes.length;
        if (payloadBytes.length > 0) {
            System.arraycopy(payloadBytes, 0, packet, idx, payloadBytes.length);
        }

        mDevice.send(AsteroidUUIDS.APP_BRIDGE_RX_CHAR, packet, this);
    }

    @Override
    public void sync() {
        registerSendReceiver();
        registerReplyReceiver();
    }

    @Override
    public void unsync() {
        cancelKeyboardInputNotification();
        unregisterSendReceiver();
        unregisterReplyReceiver();
    }

    @Override
    public HashMap<UUID, Direction> getCharacteristicUUIDs() {
        HashMap<UUID, Direction> chars = new HashMap<>();
        chars.put(AsteroidUUIDS.APP_BRIDGE_TX_CHAR, Direction.FROM_WATCH);
        chars.put(AsteroidUUIDS.APP_BRIDGE_RX_CHAR, Direction.TO_WATCH);
        return chars;
    }

    @Override
    public UUID getServiceUUID() {
        return AsteroidUUIDS.APP_BRIDGE_SERVICE_UUID;
    }
}
