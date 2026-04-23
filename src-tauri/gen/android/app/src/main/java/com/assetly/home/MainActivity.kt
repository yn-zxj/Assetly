package com.assetly.home

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.activity.enableEdgeToEdge
import androidx.activity.OnBackPressedCallback
import java.io.File
import androidx.core.content.FileProvider

class MainActivity : TauriActivity() {

  private var webViewRef: WebView? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)

    // Register back press callback to intercept all back events
    // (hardware back button + gesture navigation + system back)
    onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
      override fun handleOnBackPressed() {
        // Minimize app to background instead of exiting
        moveTaskToBack(true)
      }
    })
  }

  // Intercept hardware back key at the lowest level
  override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    if (keyCode == KeyEvent.KEYCODE_BACK) {
      moveTaskToBack(true)
      return true
    }
    return super.onKeyDown(keyCode, event)
  }

  override fun onWebViewCreate(webView: WebView) {
    super.onWebViewCreate(webView)
    webViewRef = webView

    // Disable overscroll edge effects
    webView.overScrollMode = View.OVER_SCROLL_NEVER

    // Disable zoom controls
    webView.settings.setSupportZoom(false)
    webView.settings.builtInZoomControls = false
    webView.settings.displayZoomControls = false

    // Add JavaScript interface for file sharing
    webView.addJavascriptInterface(WebAppInterface(this), "Android")

    // Clear history on each page load
    webView.webViewClient = object : android.webkit.WebViewClient() {
      override fun onPageFinished(view: WebView?, url: String?) {
        super.onPageFinished(view, url)
        view?.clearHistory()
      }
    }
  }
}

/**
 * JavaScript interface for Android native features
 */
class WebAppInterface(private val activity: MainActivity) {

    /**
     * Share text content as a file via system share panel.
     * Writes content to cache dir and shares via FileProvider.
     * Runs startActivity on UI thread to avoid WebView thread issues.
     */
    @JavascriptInterface
    fun shareTextAsFile(content: String, fileName: String, mimeType: String, title: String): Boolean {
        return try {
            // Write to cache directory (always accessible, no permission needed)
            val shareDir = File(activity.cacheDir, "share")
            if (!shareDir.exists()) shareDir.mkdirs()
            val file = File(shareDir, fileName)
            file.writeText(content)

            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                file
            )

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = Intent.createChooser(shareIntent, title)

            // Must run on UI thread
            activity.runOnUiThread {
                activity.startActivity(chooser)
            }
            true
        } catch (e: Exception) {
            android.util.Log.e("WebAppInterface", "Share failed: ${e.message}", e)
            false
        }
    }
}
