package app.iccardreader.ic_card_reader

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Uses the system document picker: no internal CSV, broad storage permission,
 * persistent URI grant, automatic upload, or card data logging. */
class HistoryCsvExport(private val activity: Activity) {
    companion object { const val REQUEST_CODE = 6413 }
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var writing = false

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "save") { result.notImplemented(); return }
        if (pendingResult != null || writing) {
            result.error("EXPORT_BUSY", "An export is already active", null)
            return
        }
        val filename = call.argument<String>("filename")
        val bytes = call.argument<ByteArray>("bytes")
        if (filename == null || !filename.matches(Regex("ic-card-history-[0-9-]+\\.csv")) ||
            bytes == null || bytes.isEmpty() || bytes.size > 1024 * 1024) {
            result.error("INVALID_EXPORT", "Invalid CSV export", null)
            return
        }
        pendingResult = result
        pendingBytes = bytes
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(
                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "text/csv"
                    putExtra(Intent.EXTRA_TITLE, filename)
                }, REQUEST_CODE
            )
        } catch (_: Exception) {
            pendingBytes = null
            pendingResult = null
            result.error("SAVE_UNAVAILABLE", "Document picker unavailable", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult ?: return true
        val bytes = pendingBytes
        val uri = data?.data
        pendingBytes = null
        if (resultCode != Activity.RESULT_OK) {
            pendingResult = null
            result.success(false)
            return true
        }
        if (uri == null || bytes == null) {
            pendingResult = null
            result.error("SAVE_FAILED", "No output destination", null)
            return true
        }
        writing = true
        Thread {
            val saved = try {
                val output = activity.contentResolver.openOutputStream(uri, "wt")
                    ?: throw IllegalStateException("No output stream")
                output.use { it.write(bytes) }
                true
            } catch (_: Exception) {
                false
            }
            activity.runOnUiThread {
                writing = false
                if (pendingResult === result) {
                    pendingResult = null
                    if (saved) result.success(true)
                    else result.error("SAVE_FAILED", "Could not write CSV", null)
                }
            }
        }.start()
        return true
    }

    fun dispose() {
        pendingBytes = null
        pendingResult?.error("EXPORT_CLOSED", "Export closed", null)
        pendingResult = null
    }
}
