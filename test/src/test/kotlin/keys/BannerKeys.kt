package keys

import com.yandex.plugin_tests_support.AndroidElementId
import com.yandex.plugin_tests_support.ScreenElement

object BannerKeys {
    val adUnitId = ScreenElement.WithId("banner-ad-unit-id", "текстовое поле Ad Unit ID")
    val loadAd = ScreenElement.WithId("banner-load-ad", "кнопку Load Ad")
    val width = ScreenElement.WithId("banner-width", "текстовое поле Width")
    val height = ScreenElement.WithId("banner-height", "текстовое поле Height")
    val inlineSwitch = ScreenElement.WithId("banner-inline", "переключатель Inline")
    val stickySwitch = ScreenElement.WithId("banner-sticky", "переключатель Sticky")
    val log = ScreenElement.WithId("banner-log", "кнопку открытия логов")
    val banner = ScreenElement.WithId("banner-ad", AndroidElementId.Tags("banner-ad"), "баннер", isNative = true)
    val videoCta = ScreenElement.WithCoordinates(Pair(300.0, 493.0), "рекламу")
}
