package keys

import com.yandex.plugin_tests_support.AndroidElementId
import com.yandex.plugin_tests_support.ScreenElement
import com.yandex.plugin_tests_support.platformDependant

object AppOpenAdKeys {
    val adUnitId = ScreenElement.WithId("banner-ad-unit-id", "текстовое поле Ad Unit ID")
    val log = ScreenElement.WithId("app-open-log", "кнопку открытия логов")
    val loadAd = ScreenElement.WithId("app-open-load-ad", "кнопку Load Ad")
    val showAd = ScreenElement.WithId("app-open-show-ad", "кнопку Show Ad")
    val ad = ScreenElement.WithId(
        iosId = "mac_interstitial",
        androidId = AndroidElementId.Tags("yma_root_layout"),
        name = "рекламу",
        isNative = true
    )
    val callToAction = ScreenElement.WithId(
        iosId = "mac_call_to_action",
        androidId = AndroidElementId.Tags("call_to_action", "yma_call_to_action", "mac_call_to_action"),
        name = "кнопку Call To Action",
        isNative = true
    )
    val closeAd = ScreenElement.WithId(
        iosId = "mac_close_view",
        androidId = AndroidElementId.Tags("close_view", "mac_close_view"),
        name = "крестик закрытия рекламы",
        isNative = true
    )

    val feedback = ScreenElement.WithCoordinates(platformDependant(ios = Pair(300.0, 240.0), android = Pair(358.0, 75.0)), "кебаб")
}
