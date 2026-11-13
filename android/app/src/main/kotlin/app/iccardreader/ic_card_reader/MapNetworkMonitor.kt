package app.iccardreader.ic_card_reader

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/** OS metadata only: no ping, HTTP probe, SSID, IP address or card data. */
class MapNetworkMonitor(context: Context) : EventChannel.StreamHandler {
    private val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
    private val handler = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null
    private var sink: EventChannel.EventSink? = null
    private var current: Network? = null
    private var last: Boolean? = null

    fun isOnline(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        return try {
            val network = manager?.activeNetwork ?: return false
            validated(manager?.getNetworkCapabilities(network))
        } catch (_: Exception) {
            false
        }
    }

    private fun validated(caps: NetworkCapabilities?): Boolean =
        caps != null && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)

    private fun publish(online: Boolean) {
        if (last != online) {
            last = online
            sink?.success(online)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stop()
        sink = events
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || manager == null) {
            publish(false)
            return
        }
        try {
            current = manager.activeNetwork
            val listener = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    handler.post {
                        if (callback !== this) return@post
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            if (current != network) {
                                current = network
                                publish(false) // Wait for validated capabilities of the new default.
                            }
                        } else {
                            publish(isOnline()) // API 23: query on main handler, not callback thread.
                        }
                    }
                }

                override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
                    val online = validated(caps)
                    handler.post {
                        if (callback !== this) return@post
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            if (current == network) publish(online)
                        } else {
                            publish(isOnline())
                        }
                    }
                }

                override fun onLost(network: Network) {
                    handler.post {
                        if (callback !== this) return@post
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            if (current == network) {
                                current = null
                                publish(false)
                            }
                        } else {
                            publish(isOnline())
                        }
                    }
                }
            }
            callback = listener
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                manager.registerDefaultNetworkCallback(listener)
            } else {
                manager.registerNetworkCallback(
                    NetworkRequest.Builder().addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build(),
                    listener,
                )
            }
            publish(isOnline())
        } catch (_: Exception) {
            stop()
            sink = events
            publish(false)
        }
    }

    override fun onCancel(arguments: Any?) = stop()

    fun stop() {
        val previous = callback
        callback = null
        if (previous != null) {
            try { manager?.unregisterNetworkCallback(previous) } catch (_: Exception) { }
        }
        handler.removeCallbacksAndMessages(null)
        sink = null
        current = null
        last = null
    }
}
