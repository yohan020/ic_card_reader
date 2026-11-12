package app.iccardreader.ic_card_reader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.Build
import android.content.Intent
import android.provider.Settings
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    private var mapNetworkMonitor: MapNetworkMonitor? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.iccardreader/coin_locker_links")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                } else {
                    result.success(CoinLockerLinks.open(this, call.argument<String>("url")))
                }
            }
        val networkMonitor = MapNetworkMonitor(applicationContext)
        mapNetworkMonitor?.stop()
        mapNetworkMonitor = networkMonitor
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "app.iccardreader/maps_network")
            .setStreamHandler(networkMonitor)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.iccardreader/maps")
            .setMethodCallHandler { call, result ->
                if (call.method == "isNetworkAvailable") {
                    result.success(networkMonitor.isOnline())
                } else if (call.method != "isConfigured") {
                    result.notImplemented()
                } else {
                    try {
                        @Suppress("DEPRECATION")
                        val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                        val key = appInfo.metaData?.getString("com.google.android.geo.API_KEY")?.trim()
                        result.success(key != null && key.startsWith("AIza") && key.length > 30)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.iccardreader/nfc_settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                } else {
                    try {
                        startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
                        result.success(true)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.iccardreader/app_info")
            .setMethodCallHandler { call, result ->
                if (call.method != "installedVersion") {
                    result.notImplemented()
                } else {
                    try {
                        @Suppress("DEPRECATION")
                        val info = packageManager.getPackageInfo(packageName, 0)
                        @Suppress("DEPRECATION")
                        val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
                        result.success("${info.versionName} ($code)")
                    } catch (error: Exception) {
                        result.error("VERSION_UNAVAILABLE", "Installed version unavailable", null)
                    }
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "app.iccardreader/maps_network")
            .setStreamHandler(null)
        mapNetworkMonitor?.stop()
        mapNetworkMonitor = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
