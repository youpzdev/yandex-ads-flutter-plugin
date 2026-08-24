package keys

import com.yandex.plugin_tests_support.AndroidElementId
import com.yandex.plugin_tests_support.ScreenElement

object RewardedKeys {
    val adUnitId = ScreenElement.WithId("banner-ad-unit-id", "текстовое поле Ad Unit ID")
    val log = ScreenElement.WithId("rewarded-log", "кнопку открытия логов")
    val loadAd = ScreenElement.WithId("rewarded-load-ad", "кнопку Load Ad")
    val showAd = ScreenElement.WithId("rewarded-show-ad", "кнопку Show Ad")
    val ad = ScreenElement.WithId(
        iosId = "mac_rewarded",
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
    var closeAd = ScreenElement.WithId(
        iosId = "mac_close_button",
        androidId = AndroidElementId.Tags("close", "close_view", "close_button", "yma_close_button", "mac_close_button"),
        name = "крестик",
        isNative = true
    )
}
