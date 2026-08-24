package keys

import com.yandex.plugin_tests_support.AndroidElementId
import com.yandex.plugin_tests_support.ScreenArea
import com.yandex.plugin_tests_support.ScreenElement
import org.openqa.selenium.Rectangle

object DebugPanelKeys {
    val root = ScreenElement.WithId(
        iosId = "null",
        androidId = AndroidElementId.ResourceId("com.yandex.mobile.ads.flutter.example:id/debug_panel_root"),
        name = "дебаг-панель"
    )
    val integrationStatus = ScreenArea(Rectangle(10, 370, 37, 117), "integration_status")
    val hasUserConsentKey = "Has User Consent"
    val ageRestrictedUser = "Age Restricted User"
    val hasLocationConsent = "Has Location Consent"
    val backArrow = ScreenElement.WithId(iosId = "arrow back", androidId = AndroidElementId.ContentDesc("Back"), name = "назад")
}
