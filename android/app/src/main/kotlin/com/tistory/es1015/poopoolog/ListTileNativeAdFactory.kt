package com.tistory.es1015.poopoolog

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String?, Any?>?,
    ): NativeAdView {
        val view =
            LayoutInflater.from(context)
                .inflate(R.layout.list_tile_native_ad, null) as NativeAdView

        val headlineView = view.findViewById<TextView>(R.id.ad_headline)
        val bodyView = view.findViewById<TextView>(R.id.ad_body)
        val iconView = view.findViewById<ImageView>(R.id.ad_icon)

        headlineView.text = nativeAd.headline
        view.headlineView = headlineView

        nativeAd.body?.let {
            bodyView.text = it
            bodyView.visibility = View.VISIBLE
        } ?: run { bodyView.visibility = View.GONE }
        view.bodyView = bodyView

        nativeAd.icon?.let {
            iconView.setImageDrawable(it.drawable)
            iconView.visibility = View.VISIBLE
        } ?: run { iconView.visibility = View.GONE }
        view.iconView = iconView

        view.setNativeAd(nativeAd)
        return view
    }
}
