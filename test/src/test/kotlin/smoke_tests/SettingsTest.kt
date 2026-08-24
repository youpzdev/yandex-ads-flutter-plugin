package smoke_tests

import callbacks.BannerCallbacks
import com.yandex.plugin_tests_support.Functionalities.Settings
import com.yandex.plugin_tests_support.TestName
import com.yandex.plugin_tests_support.assertRequest
import com.yandex.plugin_tests_support.assertRequestBody
import com.yandex.plugin_tests_support.assertScreenshot
import com.yandex.plugin_tests_support.assertSwitch
import com.yandex.plugin_tests_support.checkDebugPanelSetting
import com.yandex.plugin_tests_support.clearSnifferLog
import com.yandex.plugin_tests_support.getDebugPanelSetting
import com.yandex.plugin_tests_support.platformDependant
import com.yandex.plugin_tests_support.scroll
import com.yandex.plugin_tests_support.scrollTo
import com.yandex.plugin_tests_support.ScrollDirection
import com.yandex.plugin_tests_support.waitAndClick
import com.yandex.plugin_tests_support.waitForElement
import io.qameta.allure.Epic
import io.qameta.allure.Feature
import keys.BannerKeys
import keys.CommonKeys
import keys.DebugPanelKeys
import keys.HomeKeys
import keys.SettingsKeys
import org.testng.annotations.Test
import support.MockAdUnits
import support.ScreenName
import support.setAdUnitId
import support.waitLogsCallback

@Epic("E2E тесты")
@Feature(Settings)
class SettingsTest: BaseFlutterTest() {

    @Test
    @TestName("Flutter Debug Error Indicator")
    fun testDebugErrorIndicator() {
        waitAndClick(HomeKeys.settingsPage)
        waitAndClick(SettingsKeys.debugErrorIndicator)
        waitAndClick(CommonKeys.back)
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitForElement(BannerKeys.banner)
    }

    @Test
    @TestName("Flutter Настройки в дебаг панели")
    fun testDebugPanelSettings() {
        waitAndClick(HomeKeys.settingsPage)
        waitAndClick(SettingsKeys.userConsent)
        waitAndClick(SettingsKeys.locationConsent)
        waitAndClick(SettingsKeys.ageRestrictedUser)
        assertSwitch(SettingsKeys.userConsent, true)
        assertSwitch(SettingsKeys.locationConsent, true)
        assertSwitch(SettingsKeys.ageRestrictedUser, true)
        waitAndClick(CommonKeys.back)
        waitAndClick(HomeKeys.debugPanel)
        scrollTo(getDebugPanelSetting(DebugPanelKeys.hasUserConsentKey))
        scroll(ScrollDirection.down, 50.0)
        checkDebugPanelSetting(DebugPanelKeys.ageRestrictedUser, "Yes")
        platformDependant(android = { ->
            checkDebugPanelSetting(DebugPanelKeys.hasLocationConsent, "Yes")
        })
        checkDebugPanelSetting(DebugPanelKeys.hasUserConsentKey, "Yes")
        waitAndClick(CommonKeys.back)
        waitAndClick(HomeKeys.settingsPage)
        waitAndClick(SettingsKeys.userConsent)
        waitAndClick(SettingsKeys.locationConsent)
        waitAndClick(SettingsKeys.ageRestrictedUser)
        assertSwitch(SettingsKeys.userConsent, false)
        assertSwitch(SettingsKeys.locationConsent, false)
        assertSwitch(SettingsKeys.ageRestrictedUser, false)
        waitAndClick(CommonKeys.back)
        waitAndClick(HomeKeys.debugPanel)
        scrollTo(getDebugPanelSetting(DebugPanelKeys.hasUserConsentKey))
        scroll(ScrollDirection.down, 50.0)
        checkDebugPanelSetting(DebugPanelKeys.ageRestrictedUser, "No")
        checkDebugPanelSetting(DebugPanelKeys.hasLocationConsent, "No")
        checkDebugPanelSetting(DebugPanelKeys.hasUserConsentKey, "No")
    }

    @Test
    @TestName("Flutter: Проверка DebugPanel")
    fun testDebugPanel() {
        waitAndClick(HomeKeys.debugPanel)
        platformDependant(android = { ->
            waitForElement(DebugPanelKeys.root)
            assertScreenshot(DebugPanelKeys.integrationStatus, "integration_status")
        })
        checkDebugPanelSetting("Application ID")
        checkDebugPanelSetting("App Version")
        platformDependant(ios = { ->
            checkDebugPanelSetting("iOS Version")
        }, android = {
            checkDebugPanelSetting("System")
            checkDebugPanelSetting("API Level")
        })
        checkDebugPanelSetting("SDK Version")
        checkDebugPanelSetting("SDK Integration Status")
        try {
            checkDebugPanelSetting("Completed Integration")
        } catch (_: Exception) {
            checkDebugPanelSetting("Invalid Integration")
        }
        scrollTo(getDebugPanelSetting(DebugPanelKeys.hasUserConsentKey))
        scroll(ScrollDirection.down, 50.0)
        checkDebugPanelSetting(DebugPanelKeys.ageRestrictedUser)
        checkDebugPanelSetting(DebugPanelKeys.hasLocationConsent)
        checkDebugPanelSetting(DebugPanelKeys.hasUserConsentKey)
        checkDebugPanelSetting("TCF Consent")
    }

    @Test
    @TestName("Flutter Включение настроек в Settings")
    fun testSettings() {
        waitAndClick(HomeKeys.settingsPage)
        waitAndClick(SettingsKeys.userConsent)
        waitAndClick(SettingsKeys.locationConsent)
        waitAndClick(SettingsKeys.ageRestrictedUser)
        assertSwitch(SettingsKeys.userConsent, true)
        assertSwitch(SettingsKeys.locationConsent, true)
        assertSwitch(SettingsKeys.ageRestrictedUser, true)
        waitAndClick(CommonKeys.back)
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        waitAndClick(BannerKeys.stickySwitch)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        assertRequest("/v1/startup")
        platformDependant(ios = { ->
            assertRequestBody("/v4/ad", Pair("user_consent", "1"))
            assertRequestBody("/v4/ad", Pair("age_restricted_user", "1"))
        })
        clearSnifferLog()
        waitAndClick(CommonKeys.back)
        waitAndClick(HomeKeys.settingsPage)
        waitAndClick(SettingsKeys.userConsent)
        waitAndClick(SettingsKeys.locationConsent)
        waitAndClick(SettingsKeys.ageRestrictedUser)
        assertSwitch(SettingsKeys.userConsent, false)
        assertSwitch(SettingsKeys.locationConsent, false)
        assertSwitch(SettingsKeys.ageRestrictedUser, false)
        waitAndClick(CommonKeys.back)
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        waitAndClick(BannerKeys.stickySwitch)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        assertRequest("/v1/startup")
        platformDependant(ios = { ->
            assertRequestBody("/v4/ad", Pair("user_consent", "0"))
            assertRequestBody("/v4/ad", Pair("age_restricted_user", "0"))
        })
    }
}
