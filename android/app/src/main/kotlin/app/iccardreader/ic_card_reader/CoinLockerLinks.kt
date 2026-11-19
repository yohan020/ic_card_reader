package app.iccardreader.ic_card_reader

import android.content.Context
import android.content.Intent
import android.net.Uri
import java.net.URI

/** Opens only curated-site HTTPS addresses; never appends user/card data. */
internal object CoinLockerLinks {
    private val hosts = setOf("coin-locker.net", "coinlocker-shiori.com", "coinlocker.click")

    fun open(context: Context, address: String?): Boolean {
        if (address == null) return false
        return try {
            val parsed = URI(address)
            if (parsed.scheme != "https" || parsed.host !in hosts ||
                parsed.userInfo != null || parsed.port != -1 ||
                parsed.rawQuery != null || parsed.rawFragment != null ||
                parsed.rawPath.isNullOrEmpty()) {
                false
            } else {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(address)).apply {
                    addCategory(Intent.CATEGORY_BROWSABLE)
                }
                context.startActivity(intent)
                true
            }
        } catch (_: Exception) {
            // Includes missing browser/activity. Recover in Flutter without a crash.
            false
        }
    }
}
