package app.iccardreader.ic_card_reader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.content.Intent
import android.provider.Settings

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
}
