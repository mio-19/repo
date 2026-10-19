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
import android.os.Build;
import android.util.Log;

import org.asteroidos.sync.asteroid.IAsteroidDevice;
import org.asteroidos.sync.utils.AsteroidUUIDS;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.UUID;

/**
 * Generic AppBridge connectivity service for AsteroidOS.
 * Provides a bidirectional BLE tunnel between smartwatch applications and Android apps,
 * mapping compact app aliases ("cam" <-> "org.asteroidos.camera", "spo2" <-> "org.asteroidos.spo2")
 * to guarantee control messages fit within standard BLE ATT packet MTU limits.
 */
public class AppBridgeService implements IConnectivityService {
    public static final String TAG = "AppBridgeService";

    public static final String ACTION_RECEIVE_FROM_WATCH = "nodomain.freeyourgadget.gadgetbridge.ACTION_RECEIVE_FROM_WATCH";
    public static final String ACTION_SEND_TO_WATCH = "nodomain.freeyourgadget.gadgetbridge.ACTION_SEND_TO_WATCH";
    public static final String EXTRA_APP_ID = "extra_app_id";
    public static final String EXTRA_ACTION = "extra_action";
    public static final String EXTRA_PAYLOAD_BYTES = "extra_payload_bytes";
    public static final String EXTRA_PAYLOAD_STRING = "extra_payload_string";

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
                handleSendToWatchIntent(intent);
            }
        };
        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_SEND_TO_WATCH);
        filter.addAction("org.asteroidos.sync.ACTION_SEND_TO_WATCH");

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            mCtx.registerReceiver(mSendReceiver, filter, Context.RECEIVER_EXPORTED);
        } else {
            mCtx.registerReceiver(mSendReceiver, filter);
        }
    }

    private synchronized void unregisterSendReceiver() {
        if (mSendReceiver != null) {
            try {
                mCtx.unregisterReceiver(mSendReceiver);
            } catch (Exception e) {
                Log.w(TAG, "Failed to unregister send receiver", e);
            }
            mSendReceiver = null;
        }
    }

    /**
     * Process incoming generic App Bridge notification from AsteroidOS watch.
     * Wire Format: [0xA0][appIdLen:1B][appId][actionLen:1B][action][payload]
     */
    private void handleAppBridgeData(byte[] value) {
        if (value == null || value.length < 3) return;
        if ((value[0] & 0xFF) != 0xA0) {
            Log.w(TAG, "AppBridge: invalid magic byte 0x" + Integer.toHexString(value[0] & 0xFF));
            return;
        }
        try {
            int offset = 1;
            int appIdLen = value[offset++] & 0xFF;
            if (value.length < offset + appIdLen + 1) return;
            String appId = new String(value, offset, appIdLen, StandardCharsets.UTF_8);
            if ("cam".equals(appId) || "camera".equals(appId)) {
                appId = "org.asteroidos.camera";
            } else if ("spo2".equals(appId)) {
                appId = "org.asteroidos.spo2";
            }
            offset += appIdLen;

            int actionLen = value[offset++] & 0xFF;
            if (value.length < offset + actionLen) return;
            String action = new String(value, offset, actionLen, StandardCharsets.UTF_8);
            offset += actionLen;

            int payloadLen = value.length - offset;
            byte[] payload = new byte[payloadLen];
            System.arraycopy(value, offset, payload, 0, payloadLen);
            String payloadStr = new String(payload, StandardCharsets.UTF_8);

            Log.i(TAG, "AppBridge message received: app=" + appId + ", action=" + action + ", bytes=" + payloadLen);

            // Forward to Android system via standard Gadgetbridge action (for cross-companion compatibility)
            Intent gbIntent = new Intent(ACTION_RECEIVE_FROM_WATCH);
            gbIntent.putExtra(EXTRA_APP_ID, appId);
            gbIntent.putExtra(EXTRA_ACTION, action);
            gbIntent.putExtra(EXTRA_PAYLOAD_BYTES, payload);
            gbIntent.putExtra(EXTRA_PAYLOAD_STRING, payloadStr);
            mCtx.sendBroadcast(gbIntent);

            // Forward via native AsteroidOS Sync action
            Intent syncIntent = new Intent("org.asteroidos.sync.ACTION_RECEIVE_FROM_WATCH");
            syncIntent.putExtra(EXTRA_APP_ID, appId);
            syncIntent.putExtra(EXTRA_ACTION, action);
            syncIntent.putExtra(EXTRA_PAYLOAD_BYTES, payload);
            syncIntent.putExtra(EXTRA_PAYLOAD_STRING, payloadStr);
            mCtx.sendBroadcast(syncIntent);
        } catch (Exception e) {
            Log.e(TAG, "Failed to parse AppBridge data", e);
        }
    }

    /**
     * Handles outgoing Intent from companion Android applications wishing to send to watch.
     */
    private void handleSendToWatchIntent(Intent intent) {
        if (intent == null) return;
        String targetApp = intent.getStringExtra(EXTRA_APP_ID);
        String appAction = intent.getStringExtra(EXTRA_ACTION);
        byte[] payload = intent.getByteArrayExtra(EXTRA_PAYLOAD_BYTES);
        if (payload == null && intent.hasExtra(EXTRA_PAYLOAD_STRING)) {
            String str = intent.getStringExtra(EXTRA_PAYLOAD_STRING);
            if (str != null) {
                payload = str.getBytes(StandardCharsets.UTF_8);
            }
        }
        if (payload == null) {
            payload = new byte[0];
        }
        if (targetApp != null && appAction != null) {
            sendAppBridgeMessage(targetApp, appAction, payload);
        }
    }

    private void sendAppBridgeMessage(String appId, String action, byte[] payload) {
        try {
            String wireAppId = appId;
            if ("org.asteroidos.camera".equals(appId)) {
                wireAppId = "cam";
            } else if ("org.asteroidos.spo2".equals(appId)) {
                wireAppId = "spo2";
            }
            byte[] appIdBytes = wireAppId.getBytes(StandardCharsets.UTF_8);
            byte[] actionBytes = action.getBytes(StandardCharsets.UTF_8);
            if (appIdBytes.length > 255 || actionBytes.length > 255) {
                Log.w(TAG, "AppBridge: appId or action length exceeds 255 bytes");
                return;
            }
            byte[] packet = new byte[3 + appIdBytes.length + actionBytes.length + payload.length];
            int idx = 0;
            packet[idx++] = (byte) 0xA0;
            packet[idx++] = (byte) appIdBytes.length;
            System.arraycopy(appIdBytes, 0, packet, idx, appIdBytes.length);
            idx += appIdBytes.length;
            packet[idx++] = (byte) actionBytes.length;
            System.arraycopy(actionBytes, 0, packet, idx, actionBytes.length);
            idx += actionBytes.length;
            System.arraycopy(payload, 0, packet, idx, payload.length);

            mDevice.send(AsteroidUUIDS.APP_BRIDGE_RX_CHAR, packet, this);
            Log.i(TAG, "Queued AppBridge message to watch: app=" + appId + ", action=" + action);
        } catch (Exception e) {
            Log.e(TAG, "Error sending AppBridge message", e);
        }
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
