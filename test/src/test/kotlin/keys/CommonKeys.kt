package keys

import com.yandex.plugin_tests_support.AndroidElementId
import com.yandex.plugin_tests_support.ScreenElement
import com.yandex.plugin_tests_support.platformDependant

object CommonKeys {
    val back = ScreenElement.WithCoordinates(platformDependant(ios = Pair(25.0, 95.0), android = Pair(27.0, 53.0)), "кнопку назад")
    val adRequest = ScreenElement.WithId("ad-request", "кнопку Ad request")
    val logText = ScreenElement.WithId("common-log-text", "окно логов")
    val logClear = ScreenElement.WithId("common-log-clear", "очистка логов")
    val adtuneContainer = ScreenElement.WithId(
        iosId = "mac_native_adtune_container",
        androidId = AndroidElementId.ResourceId("app:id/adtune_webview_container"),
        name = "вьюшка с меню адтюна",
        isNative = true
    )
    val callToAction = ScreenElement.WithId(
        iosId = "mac_call_to_action",
        androidId = AndroidElementId.Tags("call_to_action", "yma_call_to_action", "mac_call_to_action"),
        name = "кнопку Call To Action",
        isNative = true
    )
    val title = ScreenElement.WithId(
        iosId = "mac_title",
        androidId = AndroidElementId.Tags("title", "yma_title", "mac_title"),
        name = "заголовок рекламы",
        isNative = true
    )
    val media = ScreenElement.WithId(
        iosId = "mac_media",
        androidId = AndroidElementId.Tags("media", "yma_media", "mac_media"),
        name = "картинку",
        isNative = true
    )
    val feedback = ScreenElement.WithId(
        iosId = "mac_feedback",
        androidId = AndroidElementId.Tags("feedback", "yma_feedback", "mac_feedback"),
        name = "кебаб",
        isNative = true
    )
    val closeAd = ScreenElement.WithId(
        iosId = "mac_close_button",
        androidId = AndroidElementId.Tags("close", "mac_close_button"),
        name = "кнопку закрытия рекламы",
        isNative = true
    )
    val sponsored = ScreenElement.WithId(
        iosId = "mac_sponsored",
        androidId = AndroidElementId.Tags("sponsored", "mac_sponsored"),
        name = "надпись реклама",
        isNative = true
    )
    val closeView = ScreenElement.WithId(
        iosId = "mac_close_view",
        androidId = AndroidElementId.Tags("close_view", "mac_close_view"),
        name = "кнопку закрытия рекламы",
        isNative = true
    )
    val skipAd = ScreenElement.WithId(
        iosId = "mac_skip_button",
        androidId = AndroidElementId.Tags("skip_button", "yma_skip_button", "mac_skip_button"),
        name = "кнопку стрелки",
        isNative = true
    )
}
