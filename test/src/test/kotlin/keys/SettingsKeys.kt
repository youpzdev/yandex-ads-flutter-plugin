package keys

import com.yandex.plugin_tests_support.ScreenElement

object SettingsKeys {
    val userConsent = ScreenElement.WithId("settings-user-consent", "тумблер User Consent")
    val locationConsent = ScreenElement.WithId("settings-location-consent", "тумблер Location Consent")
    val ageRestrictedUser = ScreenElement.WithId("settings-age-restricted", "тумблер Age Restricted User")
    val loggingEnabled = ScreenElement.WithId("settings-logging", "тумблер Logging Enabled")
    val debugErrorIndicator = ScreenElement.WithId("settings-debug-error-indicator", "тумблер Debug Error Indicator")
}
