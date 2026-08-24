package support

import callbacks.AppOpenAdCallbacks
import callbacks.BannerCallbacks
import callbacks.InterstitialCallbacks
import callbacks.RewardedCallbacks
import com.yandex.plugin_tests_support.BaseTest
import com.yandex.plugin_tests_support.ScreenElement
import com.yandex.plugin_tests_support.allureStep
import com.yandex.plugin_tests_support.enterText
import com.yandex.plugin_tests_support.isElementVisible
import com.yandex.plugin_tests_support.isWebViewAppActive
import com.yandex.plugin_tests_support.platformDependant
import com.yandex.plugin_tests_support.waitAndClick
import com.yandex.plugin_tests_support.waitForElement
import keys.AppOpenAdKeys
import keys.BannerKeys
import keys.CommonKeys
import keys.InterstitialKeys
import keys.RewardedKeys
import java.time.Duration

enum class ScreenName {
    AppOpenAd {
        override fun adUnitIdField() = AppOpenAdKeys.adUnitId
        override fun adLoadedCallback() = AppOpenAdCallbacks.loaded
    }, Banner {
        override fun adUnitIdField() = BannerKeys.adUnitId
        override fun adLoadedCallback() = BannerCallbacks.loaded
    }, Interstitial {
        override fun adUnitIdField() = InterstitialKeys.adUnitId
        override fun adLoadedCallback() = InterstitialCallbacks.loaded
    }, Rewarded {
        override fun adUnitIdField() = RewardedKeys.adUnitId
        override fun adLoadedCallback() = RewardedCallbacks.loaded
    };

    abstract fun adUnitIdField(): ScreenElement
    abstract fun adLoadedCallback(): String
}

fun BaseTest.setAdUnitId(screen: ScreenName, adUnitId: String, isDry: Boolean = false) {
    if (isDry) {
        allureStep("Ввести текст \"$adUnitId\" в поле Ad unit ID")
    } else {
        enterText(screen.adUnitIdField(), adUnitId)
    }
}


fun BaseTest.clickSkipButtonIfPresent() {
    if (isElementVisible(CommonKeys.skipAd)) {
        waitAndClick(CommonKeys.skipAd)
    }
}

fun BaseTest.checkAdtuneVisible() {
    allureStep("Проверить, что адтюн отображется") {
        platformDependant(ios = { ->
            waitForElement(CommonKeys.adtuneContainer)
        }, android = {
            isWebViewAppActive("com.yandex.mobile.ads")
        })
    }
}

