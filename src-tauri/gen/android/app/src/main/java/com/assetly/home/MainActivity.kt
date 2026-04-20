package com.assetly.home

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.activity.enableEdgeToEdge
import androidx.activity.OnBackPressedCallback
import java.io.File
import androidx.core.content.FileProvider

class MainActivity : TauriActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)

    // Completely disable back navigation (both button and swipe gesture)
    // This prevents ALL forms of back navigation
    onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
      override fun handleOnBackPressed() {
        // Do nothing - completely disable back
        // This handles both hardware back button and swipe gesture on some devices
      }
    })
  }

  override fun onWebViewCreate(webView: WebView) {
    super.onWebViewCreate(webView)
    // Disable overscroll edge effects (removes the glow at edges)
    webView.overScrollMode = View.OVER_SCROLL_NEVER
    // Completely disable WebView navigation history (no back/forward)
    disableWebViewNavigation(webView)
    
    // Add JavaScript interface for file sharing
    webView.addJavascriptInterface(WebAppInterface(this), "Android")
    
    // Monitor page navigation and clear history after each load
    webView.webViewClient = object : android.webkit.WebViewClient() {
      override fun onPageFinished(view: WebView?, url: String?) {
        super.onPageFinished(view, url)
        // Clear history after each page load to prevent back/forward
        view?.clearHistory()
      }
    }
  }

  private fun disableWebViewNavigation(webView: WebView) {
    // Disable zoom controls
    webView.settings.setSupportZoom(false)
    webView.settings.builtInZoomControls = false
    webView.settings.displayZoomControls = false

    // Clear history to prevent any back/forward navigation
    webView.clearHistory()
  }
}

/**
 * JavaScript interface for Android native features
 */
class WebAppInterface(private val activity: MainActivity) {
    
    @JavascriptInterface
    fun shareFile(filePath: String, mimeType: String, title: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                return false
            }
            
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
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(chooser)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
