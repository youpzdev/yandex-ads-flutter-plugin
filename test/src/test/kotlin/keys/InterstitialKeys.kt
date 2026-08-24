package keys

import com.yandex.plugin_tests_support.AndroidElementId
import com.yandex.plugin_tests_support.ScreenElement
import com.yandex.plugin_tests_support.platformDependant

object InterstitialKeys {
    val adUnitId = ScreenElement.WithId("banner-ad-unit-id", "текстовое поле Ad Unit ID")
    val log = ScreenElement.WithId("interstitial-log", "кнопку открытия логов")
    val loadAd = ScreenElement.WithId("interstitial-load-ad", "кнопку Load Ad")
    val showAd = ScreenElement.WithId("interstitial-show-ad", "кнопку Show Ad")
    val callToAction = ScreenElement.WithId(
        iosId = "mac_call_to_action",
        androidId = AndroidElementId.Tags("call_to_action", "yma_call_to_action", "mac_call_to_action"),
        name = "кнопку Call To Action",
        isNative = true
    )
    val ad = ScreenElement.WithId(
        iosId = "mac_interstitial",
        androidId = AndroidElementId.Tags("yma_root_layout"),
        name = "рекламу",
        isNative = true
    )
    val closeAd = ScreenElement.WithId(
        iosId = "mac_close_button",
        androidId = AndroidElementId.Tags("close", "close_view", "close_button", "yma_close_button", "mac_close_button"),
        name = "крестик",
        isNative = true
    )
    val skipButton = ScreenElement.WithId(
        iosId = "mac_skip_button",
        androidId = AndroidElementId.Tags("skip_button"),
        name = "кнопку пропуска",
        isNative = true
    )

    val feedback = ScreenElement.WithCoordinates(platformDependant(ios = Pair(205.0, 295.0), android = Pair(310.0, 725.0)), "кебаб")
}
