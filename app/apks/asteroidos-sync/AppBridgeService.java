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

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Process;
import android.util.Log;

import org.asteroidos.sync.asteroid.IAsteroidDevice;
import org.asteroidos.sync.utils.AsteroidUUIDS;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * AppBridge connectivity service for AsteroidOS: a BLE tunnel between the watch camera remote and
 * the GrapheneOS Camera app.
 *
 * Threat model: other apps on the phone must neither read what the watch sends nor be able to make
 * the watch act. Therefore:
 *  - broadcasts to the camera app are explicit (setPackage) and carry a permission which the user
 *    must grant to the camera app; the system then only delivers them to holders of a permission
 *    that this app defines,
 *  - broadcasts from the camera app are only accepted if the sender holds the same permission and
 *    the system reports the camera package's uid as the sender,
 *  - only fixed, allowlisted actions are relayed; payloads are never forwarded and telemetry
 *    (such as SpO2) is never broadcast or logged.
 *
 * Wire format: [0xA0][appIdLen:1B][appId][actionLen:1B][action][payload]. The compact app id "cam"
 * maps to "org.asteroidos.camera".
 */
public class AppBridgeService implements IConnectivityService {
    public static final String TAG = "AppBridgeService";

    public static final String PERMISSION_APP_BRIDGE = "org.asteroidos.sync.permission.APP_BRIDGE";
    public static final String ACTION_RECEIVE_FROM_WATCH = "org.asteroidos.sync.ACTION_RECEIVE_FROM_WATCH";
    public static final String ACTION_SEND_TO_WATCH = "org.asteroidos.sync.ACTION_SEND_TO_WATCH";
    public static final String EXTRA_APP_ID = "extra_app_id";
    public static final String EXTRA_ACTION = "extra_action";

    private static final String CAMERA_PACKAGE = "app.grapheneos.camera";
    private static final String CAMERA_APP_ID = "org.asteroidos.camera";
    private static final String CAMERA_WIRE_APP_ID = "cam";
    private static final int MAX_PACKET = 512;

    private static final Set<String> WATCH_TO_PHONE_ACTIONS = new HashSet<>(Arrays.asList(
            "capture", "flip", "zoom_in", "zoom_out", "torch", "mode_photo", "mode_video",
            "status_query"));
    private static final Set<String> PHONE_TO_WATCH_ACTIONS = new HashSet<>(Arrays.asList(
            "ready", "paused", "photo_captured", "video_started", "video_stopped"));

    private final Context mCtx;
    private final IAsteroidDevice mDevice;
    private BroadcastReceiver mSendReceiver;

    public AppBridgeService(Context ctx, IAsteroidDevice device) {
        this.mCtx = ctx;
        this.mDevice = device;

        device.registerCallback(AsteroidUUIDS.APP_BRIDGE_TX_CHAR, this::handleAppBridgeData);
        registerSendReceiver();
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

    private boolean isSentFromCameraApp(BroadcastReceiver receiver) {
        // Fail closed: the sender uid is only available on Android 14+.
        // (compileSdk is older than that, hence the reflective call.)
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

    /**
     * Process incoming App Bridge frame from the AsteroidOS watch.
     * Only camera remote actions are relayed, without payload.
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

        // Everything but the camera remote (including SpO2 telemetry) stays on the watch link.
        if (!CAMERA_WIRE_APP_ID.equals(appId) || !WATCH_TO_PHONE_ACTIONS.contains(action)) {
            Log.d(TAG, "AppBridge: ignoring frame for unsupported app or action");
            return;
        }

        Intent intent = new Intent(ACTION_RECEIVE_FROM_WATCH)
                .setPackage(CAMERA_PACKAGE)
                .putExtra(EXTRA_APP_ID, CAMERA_APP_ID)
                .putExtra(EXTRA_ACTION, action);
        // Delivered only to the camera app and only if the user granted it the bridge permission.
        mCtx.sendBroadcast(intent, PERMISSION_APP_BRIDGE);
    }

    /** Handles status updates from the camera app that are meant for the watch. */
    private void handleSendToWatchIntent(Intent intent, BroadcastReceiver receiver) {
        if (intent == null || !ACTION_SEND_TO_WATCH.equals(intent.getAction())) return;
        if (!isSentFromCameraApp(receiver)) {
            Log.w(TAG, "AppBridge: dropping message not sent by " + CAMERA_PACKAGE);
            return;
        }
        if (!CAMERA_APP_ID.equals(intent.getStringExtra(EXTRA_APP_ID))) return;
        String action = intent.getStringExtra(EXTRA_ACTION);
        if (action == null || !PHONE_TO_WATCH_ACTIONS.contains(action)) return;
        sendAppBridgeMessage(CAMERA_WIRE_APP_ID, action);
    }

    private void sendAppBridgeMessage(String wireAppId, String action) {
        byte[] appIdBytes = wireAppId.getBytes(StandardCharsets.UTF_8);
        byte[] actionBytes = action.getBytes(StandardCharsets.UTF_8);
        byte[] packet = new byte[3 + appIdBytes.length + actionBytes.length];
        int idx = 0;
        packet[idx++] = (byte) 0xA0;
        packet[idx++] = (byte) appIdBytes.length;
        System.arraycopy(appIdBytes, 0, packet, idx, appIdBytes.length);
        idx += appIdBytes.length;
        packet[idx++] = (byte) actionBytes.length;
        System.arraycopy(actionBytes, 0, packet, idx, actionBytes.length);

        mDevice.send(AsteroidUUIDS.APP_BRIDGE_RX_CHAR, packet, this);
    }

    @Override
    public void sync() {
        registerSendReceiver();
    }

    @Override
    public void unsync() {
        unregisterSendReceiver();
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
