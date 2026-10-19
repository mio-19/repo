package app.grapheneos.camera.stream

import android.graphics.Bitmap
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.net.Inet4Address
import java.net.NetworkInterface
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicReference

class PreviewStreamServer(private val port: Int = 8089) {
    companion object {
        private const val TAG = "PreviewStreamServer"
        private const val BOUNDARY = "--frame"
    }

    private var serverSocket: ServerSocket? = null
    private var isRunning = false
    private val clientStreams = CopyOnWriteArrayList<OutputStream>()
    private val latestFrame = AtomicReference<ByteArray?>(null)
    private var serverThread: Thread? = null

    val clientCount: Int
        get() = clientStreams.size

    val hasClients: Boolean
        get() = clientStreams.isNotEmpty()

    fun start() {
        if (isRunning) return
        isRunning = true
        serverThread = Thread({
            try {
                val server = ServerSocket(port)
                serverSocket = server
                Log.i(TAG, "Preview stream server started on port $port")
                while (isRunning && !server.isClosed) {
                    val socket = server.accept()
                    Thread({ handleClient(socket) }, "StreamClient-${socket.port}").start()
                }
            } catch (e: Exception) {
                if (isRunning) {
                    Log.e(TAG, "Server socket error", e)
                }
            }
        }, "PreviewStreamServer")
        serverThread?.isDaemon = true
        serverThread?.start()
    }

    fun stop() {
        isRunning = false
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            // ignore
        }
        serverSocket = null
        for (out in clientStreams) {
            try {
                out.close()
            } catch (e: Exception) {
                // ignore
            }
        }
        clientStreams.clear()
        latestFrame.set(null)
    }

    fun updateFrame(bitmap: Bitmap, quality: Int = 65) {
        try {
            val baos = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, baos)
            val jpegBytes = baos.toByteArray()
            latestFrame.set(jpegBytes)
            if (hasClients) {
                broadcastFrame(jpegBytes)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to compress or broadcast frame", e)
        }
    }

    fun getLatestJpeg(): ByteArray? = latestFrame.get()

    private fun broadcastFrame(jpegBytes: ByteArray) {
        val header = ("$BOUNDARY\r\n" +
                "Content-Type: image/jpeg\r\n" +
                "Content-Length: ${jpegBytes.size}\r\n\r\n").toByteArray()
        val footer = "\r\n".toByteArray()

        for (out in clientStreams) {
            try {
                out.write(header)
                out.write(jpegBytes)
                out.write(footer)
                out.flush()
            } catch (e: Exception) {
                clientStreams.remove(out)
                try {
                    out.close()
                } catch (ignored: Exception) {}
            }
        }
    }

    private fun handleClient(socket: Socket) {
        try {
            val input = socket.getInputStream().bufferedReader()
            val requestLine = input.readLine() ?: return
            Log.i(TAG, "HTTP Request: $requestLine")

            val out = socket.getOutputStream()
            if (requestLine.startsWith("GET /snapshot.jpg") || requestLine.startsWith("GET /snapshot")) {
                val frame = latestFrame.get()
                if (frame != null) {
                    val resp = "HTTP/1.1 200 OK\r\n" +
                            "Content-Type: image/jpeg\r\n" +
                            "Content-Length: ${frame.size}\r\n" +
                            "Connection: close\r\n\r\n"
                    out.write(resp.toByteArray())
                    out.write(frame)
                    out.flush()
                } else {
                    val resp = "HTTP/1.1 503 Service Unavailable\r\nContent-Length: 0\r\n\r\n"
                    out.write(resp.toByteArray())
                    out.flush()
                }
                socket.close()
                return
            }

            if (requestLine.startsWith("GET /status")) {
                val ips = getLocalIpAddresses()
                val json = "{\"status\":\"streaming\",\"clients\":${clientStreams.size},\"ips\":${ips.joinToString(prefix="[", postfix="]") { "\"$it\"" }}}"
                val resp = "HTTP/1.1 200 OK\r\n" +
                        "Content-Type: application/json\r\n" +
                        "Content-Length: ${json.length}\r\n" +
                        "Connection: close\r\n\r\n$json"
                out.write(resp.toByteArray())
                out.flush()
                socket.close()
                return
            }

            // Stream endpoint: /stream.mjpg or default
            val header = "HTTP/1.1 200 OK\r\n" +
                    "Server: GOCamLiveStream\r\n" +
                    "Cache-Control: no-cache, no-store, must-revalidate\r\n" +
                    "Pragma: no-cache\r\n" +
                    "Connection: close\r\n" +
                    "Content-Type: multipart/x-mixed-replace; boundary=--frame\r\n\r\n"
            out.write(header.toByteArray())
            out.flush()

            clientStreams.add(out)
            val initialFrame = latestFrame.get()
            if (initialFrame != null) {
                out.write(("$BOUNDARY\r\nContent-Type: image/jpeg\r\nContent-Length: ${initialFrame.size}\r\n\r\n").toByteArray())
                out.write(initialFrame)
                out.write("\r\n".toByteArray())
                out.flush()
            }

            // Keep connection alive until client disconnects
            while (isRunning && !socket.isClosed && clientStreams.contains(out)) {
                Thread.sleep(500)
            }
        } catch (e: Exception) {
            // Client disconnected
        } finally {
            try {
                socket.close()
            } catch (e: Exception) {}
        }
    }

    fun getLocalIpAddresses(): List<String> {
        val localIps = mutableListOf<String>()
        val cellularIps = mutableListOf<String>()
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val iface = interfaces.nextElement()
                if (iface.isLoopback || !iface.isUp) continue
                val name = iface.name.lowercase()
                val isCellular = name.startsWith("rmnet") || name.startsWith("ccmni") || name.startsWith("pdp")
                val addresses = iface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val addr = addresses.nextElement()
                    if (addr is Inet4Address && !addr.isLoopbackAddress) {
                        addr.hostAddress?.let { ip ->
                            if (isCellular) {
                                cellularIps.add(ip)
                            } else {
                                localIps.add(ip)
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error enumerating interfaces", e)
        }
        return localIps + cellularIps
    }
}
