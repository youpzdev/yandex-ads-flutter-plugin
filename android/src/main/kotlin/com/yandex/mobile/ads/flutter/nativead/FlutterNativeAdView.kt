/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 *
 * Added in this local fork.
 */

package com.yandex.mobile.ads.flutter.nativead

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.View.MeasureSpec
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.yandex.mobile.ads.flutter.util.toAdRequest
import com.yandex.mobile.ads.common.AdBindingResult
import com.yandex.mobile.ads.nativeads.MediaView
import com.yandex.mobile.ads.nativeads.NativeAd
import com.yandex.mobile.ads.nativeads.NativeAdException
import com.yandex.mobile.ads.nativeads.NativeAdLoadListener
import com.yandex.mobile.ads.nativeads.NativeAdLoader
import com.yandex.mobile.ads.nativeads.NativeAdView
import com.yandex.mobile.ads.nativeads.NativeAdViewBinder
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlin.math.roundToInt

internal class FlutterNativeAdView(
    context: Context,
    val widthDp: Int,
    val heightDp: Int,
    template: NativeAdTemplate,
    style: NativeAdStyle,
) : PlatformView {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val density = context.resources.displayMetrics.density
    private val viewContext = context
    private val nativeAdView = NativeAdView(context)
    private var adLoader: NativeAdLoader? = null
    private val binder: NativeAdViewBinder
    private lateinit var contentView: LinearLayout
    private var eventListener: NativeAdFlutterEventListener? = null
    private var onDisposed: (() -> Unit)? = null
    private var nativeAd: NativeAd? = null
    private var destroyed = false
    private var loadPending = false
    private var pendingAdUnitId = ""
    private var loadGeneration = 0L
    private var minimumContainerWidthDp = 0
    private var minimumContainerHeightDp = 0

    init {
        binder = createTemplate(context, template, style)
    }

    override fun getView(): View = nativeAdView

    fun setEventListener(listener: NativeAdFlutterEventListener) {
        eventListener = listener
    }

    fun setOnDisposed(callback: () -> Unit) {
        onDisposed = callback
    }


    fun load(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<String, Any?>
            ?: return result.error("Args", "Args must be Map<String, Object?>", null)
        runOnMain {
            if (destroyed) {
                hideNativeAd()
                result.error("NativeAd", "Native ad cannot be loaded after it was destroyed", null)
                return@runOnMain
            }
            val generation = ++loadGeneration
            val adUnitId = args[AD_UNIT_ID] as? String ?: ""
            releaseLoadedAd()
            hideNativeAd()
            if (!canRender()) {
                loadPending = false
                sendLayoutFailure(adUnitId)
                result.success(null)
                return@runOnMain
            }
            loadPending = true
            pendingAdUnitId = adUnitId
            try {
                val loader = NativeAdLoader(viewContext)
                adLoader = loader
                loader.loadAd(args.toAdRequest(adUnitId), object : NativeAdLoadListener {
                    override fun onAdLoaded(loadedAd: NativeAd) {
                        runOnMain {
                            if (destroyed) {
                                hideNativeAd()
                                return@runOnMain
                            }
                            if (generation != loadGeneration) return@runOnMain
                            applyLoadedAd(loadedAd, adUnitId, generation)
                        }
                    }

                    override fun onAdFailedToLoad(error: com.yandex.mobile.ads.common.AdRequestError) {
                        runOnMain {
                            if (!destroyed && generation == loadGeneration) {
                                loadPending = false
                                hideNativeAd()
                                eventListener?.onAdFailedToLoad(error)
                            }
                        }
                    }
                })
                result.success(null)
            } catch (error: RuntimeException) {
                if (generation == loadGeneration) {
                    loadPending = false
                }
                result.error("NativeAd", error.message ?: "Unable to load native ad", null)
            }
        }
    }

    fun destroy(onDestroyed: () -> Unit) {
        teardown(onDone = onDestroyed)
    }

    fun cancelLoading(result: MethodChannel.Result) {
        runOnMain {
            if (!destroyed) {
                loadGeneration++
                loadPending = false
                adLoader?.cancelLoading()
                adLoader = null
                releaseLoadedAd()
                hideNativeAd()
            }
            result.success(null)
        }
    }

    override fun dispose() {
        teardown {
            onDisposed?.invoke()
            onDisposed = null
        }
    }

    private fun teardown(onDone: () -> Unit) {
        runOnMain {
            if (!destroyed) {
                destroyed = true
                loadGeneration++
                adLoader?.cancelLoading()
                adLoader = null
                if (loadPending) {
                    loadPending = false
                    eventListener?.onAdFailedToLoad(
                        DESTROYED_CODE,
                        "Native ad view was destroyed while loading",
                        pendingAdUnitId,
                    )
                }
                releaseLoadedAd()
                eventListener?.clear()
                eventListener = null
                hideNativeAd()
            }
            onDone()
        }
    }

    private fun releaseLoadedAd() {
        nativeAd?.setNativeAdEventListener(null)
        nativeAd = null
    }

    private fun applyLoadedAd(
        loadedAd: NativeAd,
        adUnitId: String,
        generation: Long,
    ) {
        nativeAd?.setNativeAdEventListener(null)
        try {
            val bindingResult = loadedAd.bindNativeAd(binder)
            if (bindingResult is AdBindingResult.Failure) {
                loadPending = false
                sendBindingFailure(adUnitId, bindingResult.exception)
                return
            }
        } catch (error: NativeAdException) {
            loadPending = false
            sendBindingFailure(adUnitId, error)
            return
        } catch (error: RuntimeException) {
            loadPending = false
            sendBindingFailure(adUnitId, error)
            return
        }
        nativeAdView.post {
            if (destroyed) {
                hideNativeAd()
                return@post
            }
            if (generation != loadGeneration) return@post
            if (!canFitBoundContent()) {
                loadPending = false
                sendLayoutFailure(adUnitId)
                return@post
            }
            loadPending = false
            nativeAd = loadedAd
            eventListener?.let(loadedAd::setNativeAdEventListener)
            nativeAdView.visibility = View.VISIBLE
            eventListener?.onAdLoaded()
        }
    }

    private fun createTemplate(
        context: Context,
        template: NativeAdTemplate,
        style: NativeAdStyle,
    ): NativeAdViewBinder {
        val cornerRadius = (style.cornerRadiusDp ?: DEFAULT_CORNER_RADIUS_DP).toPx(density)
        val contentPadding = (style.contentPaddingDp ?: DEFAULT_CONTENT_PADDING_DP).toPx(density)
        val contentPaddingDp = style.contentPaddingDp ?: DEFAULT_CONTENT_PADDING_DP
        val mediaHeightDp = template.mediaHeightDp
        minimumContainerWidthDp = MINIMUM_MEDIA_WIDTH_DP + contentPaddingDp.roundToInt() * 2
        minimumContainerHeightDp = mediaHeightDp + MINIMUM_INTERACTIVE_SIZE_DP * 2 +
            METADATA_LINE_DP * METADATA_LINE_COUNT +
            STACK_SPACING_DP * STACK_GAP_COUNT + contentPaddingDp.roundToInt() * 2
        nativeAdView.apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            background = GradientDrawable().apply {
                setColor(style.backgroundColor ?: Color.WHITE)
                this.cornerRadius = cornerRadius.toFloat()
            }
            minimumWidth = minimumContainerWidthDp.toPx(density)
            minimumHeight = minimumContainerHeightDp.toPx(density)
            visibility = View.INVISIBLE
        }
        val content = LinearLayout(context).apply {
            setPadding(contentPadding, contentPadding, contentPadding, contentPadding)
            orientation = LinearLayout.VERTICAL
        }
        contentView = content
        nativeAdView.addView(
            content,
            android.widget.FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ),
        )

        val sponsored = metadataTextView(context, style)
        val warning = metadataTextView(context, style)
        val header = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val icon = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
        }
        val titleAndBody = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
        }
        val title = TextView(context).apply {
            setTextColor(style.titleColor ?: Color.BLACK)
            textSize = TITLE_TEXT_SIZE_SP
            maxLines = TITLE_MAX_LINES
        }
        val body = TextView(context).apply {
            setTextColor(style.bodyColor ?: DEFAULT_BODY_COLOR)
            textSize = BODY_TEXT_SIZE_SP
            maxLines = BODY_MAX_LINES
        }
        val feedback = ImageView(context)
        val favicon = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_INSIDE
        }
        val media = MediaView(context)
        val metadata = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val domain = metadataTextView(context, style)
        val age = metadataTextView(context, style)
        val price = metadataTextView(context, style)
        val reviewCount = metadataTextView(context, style)
        val callToAction = TextView(context).apply {
            gravity = Gravity.CENTER
            setTextColor(style.callToActionTextColor ?: Color.WHITE)
            textSize = CTA_TEXT_SIZE_SP
            background = GradientDrawable().apply {
                setColor(style.callToActionBackgroundColor ?: DEFAULT_CTA_COLOR)
                this.cornerRadius = cornerRadius.toFloat()
            }
        }

        content.addView(sponsored, matchWidth(wrapContent()))
        content.addView(warning, matchWidth(wrapContent()))
        header.addView(icon, fixed(MINIMUM_INTERACTIVE_SIZE_DP.toPx(density), MINIMUM_INTERACTIVE_SIZE_DP.toPx(density)))
        titleAndBody.addView(title, matchWidth(wrapContent()))
        titleAndBody.addView(body, matchWidth(wrapContent()))
        header.addView(titleAndBody, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
            marginStart = HEADER_GAP_DP.toPx(density)
            marginEnd = HEADER_GAP_DP.toPx(density)
        })
        header.addView(feedback, fixed(MINIMUM_INTERACTIVE_SIZE_DP.toPx(density), MINIMUM_INTERACTIVE_SIZE_DP.toPx(density)))
        content.addView(header, matchWidth(wrapContent()))
        content.addView(media, matchWidth(mediaHeightDp.toPx(density)))
        metadata.addView(favicon, fixed(FAVICON_SIZE_DP.toPx(density), FAVICON_SIZE_DP.toPx(density)).apply {
            marginEnd = METADATA_GAP_DP.toPx(density)
        })
        metadata.addView(domain, weightedTextParams(density))
        metadata.addView(age, weightedTextParams(density))
        metadata.addView(price, weightedTextParams(density))
        metadata.addView(reviewCount, weightedTextParams(density))
        content.addView(metadata, matchWidth(wrapContent()))
        content.addView(callToAction, matchWidth(MINIMUM_INTERACTIVE_SIZE_DP.toPx(density)).apply {
            topMargin = CTA_TOP_MARGIN_DP.toPx(density)
        })

        return NativeAdViewBinder.Builder(nativeAdView)
            .setTitleView(title)
            .setBodyView(body)
            .setCallToActionView(callToAction)
            .setDomainView(domain)
            .setFaviconView(favicon)
            .setFeedbackView(feedback)
            .setIconView(icon)
            .setMediaView(media)
            .setPriceView(price)
            .setReviewCountView(reviewCount)
            .setSponsoredView(sponsored)
            .setAgeView(age)
            .setWarningView(warning)
            .build()
    }

    private fun metadataTextView(context: Context, style: NativeAdStyle): TextView {
        return TextView(context).apply {
            setTextColor(style.metadataColor ?: DEFAULT_METADATA_COLOR)
            textSize = METADATA_TEXT_SIZE_SP
            maxLines = METADATA_MAX_LINES
        }
    }

    private fun canRender(): Boolean {
        return widthDp >= minimumContainerWidthDp && heightDp >= minimumContainerHeightDp
    }

    private fun canFitBoundContent(): Boolean {
        if (!canRender()) return false
        val containerWidth = nativeAdView.width
        val containerHeight = nativeAdView.height
        if (containerWidth == 0 || containerHeight == 0) return true
        if (containerWidth < minimumContainerWidthDp.toPx(density) ||
            containerHeight < minimumContainerHeightDp.toPx(density)
        ) {
            return false
        }
        contentView.measure(
            MeasureSpec.makeMeasureSpec(containerWidth, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(containerHeight, MeasureSpec.AT_MOST),
        )
        return contentView.measuredHeight <= containerHeight
    }

    private fun sendLayoutFailure(adUnitId: String) {
        hideNativeAd()
        eventListener?.onAdFailedToLoad(
            LAYOUT_FAILURE_CODE,
            "Native ad container must be at least ${minimumContainerWidthDp}x${minimumContainerHeightDp}",
            adUnitId,
        )
    }

    private fun sendBindingFailure(adUnitId: String, error: Throwable) {
        hideNativeAd()
        eventListener?.onAdFailedToLoad(
            BINDING_FAILURE_CODE,
            error.message ?: "Unable to bind native ad",
            adUnitId,
        )
    }

    private fun weightedTextParams(density: Float): LinearLayout.LayoutParams {
        return LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
            marginEnd = METADATA_GAP_DP.toPx(density)
        }
    }

    private fun matchWidth(height: Int): LinearLayout.LayoutParams {
        return LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, height)
    }

    private fun fixed(width: Int, height: Int): LinearLayout.LayoutParams {
        return LinearLayout.LayoutParams(width, height)
    }

    private fun wrapContent(): Int = ViewGroup.LayoutParams.WRAP_CONTENT

    private fun hideNativeAd() {
        nativeAdView.visibility = View.INVISIBLE
    }

    private fun Float.toPx(density: Float): Int = (this * density).roundToInt()

    private fun Int.toPx(density: Float): Int = (this * density).roundToInt()

    private fun runOnMain(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            mainHandler.post(action)
        }
    }

    private companion object {
        const val AD_UNIT_ID = "adUnitId"
        const val DEFAULT_CORNER_RADIUS_DP = 12f
        const val DEFAULT_CONTENT_PADDING_DP = 12f
        const val FAVICON_SIZE_DP = 16
        const val HEADER_GAP_DP = 8
        const val METADATA_GAP_DP = 4
        const val CTA_TOP_MARGIN_DP = 8
        const val MINIMUM_MEDIA_WIDTH_DP = 300
        const val MINIMUM_INTERACTIVE_SIZE_DP = 64
        const val STACK_SPACING_DP = 8
        const val STACK_GAP_COUNT = 5
        const val METADATA_LINE_DP = 20
        const val METADATA_LINE_COUNT = 3
        const val LAYOUT_FAILURE_CODE = -1
        const val BINDING_FAILURE_CODE = -2
        const val DESTROYED_CODE = -3
        const val TITLE_TEXT_SIZE_SP = 16f
        const val BODY_TEXT_SIZE_SP = 14f
        const val METADATA_TEXT_SIZE_SP = 12f
        const val CTA_TEXT_SIZE_SP = 14f
        const val TITLE_MAX_LINES = 2
        const val BODY_MAX_LINES = 3
        const val METADATA_MAX_LINES = 1
        const val DEFAULT_BODY_COLOR = 0xFF3D3D3D.toInt()
        const val DEFAULT_METADATA_COLOR = 0xFF757575.toInt()
        const val DEFAULT_CTA_COLOR = 0xFF1469D8.toInt()
    }
}
