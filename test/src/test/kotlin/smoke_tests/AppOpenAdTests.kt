package smoke_tests

import callbacks.AppOpenAdCallbacks
import callbacks.CommonCallbacks
import com.yandex.plugin_tests_support.Functionalities.AppOpenAd
import com.yandex.plugin_tests_support.TestName
import com.yandex.plugin_tests_support.assertBrowserOpened
import com.yandex.plugin_tests_support.assertRequest
import com.yandex.plugin_tests_support.assertRequestBody
import com.yandex.plugin_tests_support.backgroundApp
import com.yandex.plugin_tests_support.enterText
import com.yandex.plugin_tests_support.platformDependant
import com.yandex.plugin_tests_support.returnToApp
import com.yandex.plugin_tests_support.swipe
import com.yandex.plugin_tests_support.temporarilyLockScreen
import com.yandex.plugin_tests_support.toggleNetwork
import com.yandex.plugin_tests_support.wait
import com.yandex.plugin_tests_support.waitAndClick
import com.yandex.plugin_tests_support.waitForElement
import io.qameta.allure.Epic
import io.qameta.allure.Feature
import io.qameta.allure.Story
import keys.AdRequestKeys
import keys.AppOpenAdKeys
import keys.CommonKeys
import keys.HomeKeys
import org.testng.annotations.DataProvider
import org.testng.annotations.Ignore
import org.testng.annotations.Test
import support.Constants.networkActionDelay
import support.MockAdUnits
import support.ScreenName
import support.checkAdtuneVisible
import support.setAdUnitId
import support.waitLogsCallback
import java.time.Duration

@Epic("E2E тесты")
@Story("AppOpenAd Загрузка и клик по рекламе")
@Feature(AppOpenAd)
class AppOpenAdTests: BaseFlutterTest() {

    @DataProvider(name = "demoBlocksProvider")
    fun demoBlocks(): Array<String> {
        return arrayOf(
            MockAdUnits.APP_OPEN,
        )
    }

    @Test
    @TestName("AppOpenAd: Загрузка и клик по рекламе")
    fun loadAppOpenAdAndClick() {
        waitAndClick(HomeKeys.appOpenAd)
        waitAndClick(AppOpenAdKeys.log)
        setAdUnitId(ScreenName.AppOpenAd, MockAdUnits.APP_OPEN)
        waitAndClick(AppOpenAdKeys.loadAd)
        waitLogsCallback(AppOpenAdCallbacks.loaded)
        waitAndClick(AppOpenAdKeys.showAd)
        waitForElement(AppOpenAdKeys.ad)
        waitAndClick(AppOpenAdKeys.callToAction)
        assertBrowserOpened()
        returnToApp()
        waitAndClick(AppOpenAdKeys.closeAd)
        listOf(
            AppOpenAdCallbacks.shown,
            AppOpenAdCallbacks.clicked,
            AppOpenAdCallbacks.impression,
            AppOpenAdCallbacks.dismissed
        ).forEach { callback -> waitLogsCallback(callback) }
    }

    @Test
    @TestName("Flutter Блокировка приложения")
    fun loadAppOpenAdAndBlock() {
        waitAndClick(HomeKeys.appOpenAd)
        waitAndClick(AppOpenAdKeys.log)
        setAdUnitId(ScreenName.AppOpenAd, MockAdUnits.APP_OPEN)
        waitAndClick(AppOpenAdKeys.loadAd)
        waitLogsCallback(AppOpenAdCallbacks.loaded)
        waitAndClick(AppOpenAdKeys.showAd)
        waitForElement(AppOpenAdKeys.ad)
        temporarilyLockScreen(Duration.ofSeconds(10))
        waitForElement(AppOpenAdKeys.ad)
        waitAndClick(AppOpenAdKeys.closeAd)
        waitLogsCallback(AppOpenAdCallbacks.impression)
    }

    @Test
    @TestName("AppOpenAd: Сворачивание приложения")
    fun loadAppOpenAdHideApp() {
        waitAndClick(HomeKeys.appOpenAd)
        waitAndClick(AppOpenAdKeys.log)
        setAdUnitId(ScreenName.AppOpenAd, MockAdUnits.APP_OPEN)
        waitAndClick(AppOpenAdKeys.loadAd)
        waitLogsCallback(AppOpenAdCallbacks.loaded)
        waitAndClick(AppOpenAdKeys.showAd)
        backgroundApp(Duration.ofSeconds(10), true)
        waitForElement(AppOpenAdKeys.ad)
    }

    @Test
    @TestName("AppOpenAd: Загрузка рекламы с некорректным блоком")
    fun loadAppOpenInvalidAd() {
        waitAndClick(HomeKeys.appOpenAd)
        waitAndClick(AppOpenAdKeys.log)
        setAdUnitId(ScreenName.AppOpenAd, "adlib34479-a-999")
        waitAndClick(AppOpenAdKeys.loadAd)
        waitLogsCallback(AppOpenAdCallbacks.notExist)
    }

    @Test
    @TestName("Flutter AppOpenAd Загрузка рекламы с установленными параметрами")
    fun loadAppOpenAdParameters() {
        waitAndClick(HomeKeys.appOpenAd)
        platformDependant(ios = { ->
            waitAndClick(CommonKeys.adRequest)
            waitForElement(AdRequestKeys.contextQueryField)
            swipe(Pair(200.0, 500.0), Pair(200.0, 200.0))
            enterText(AdRequestKeys.ageField, "10")
            enterText(AdRequestKeys.contextQueryField, "contextQuery")
            enterText(AdRequestKeys.genderField, "male")
            waitAndClick(AdRequestKeys.themeField)
            waitAndClick(AdRequestKeys.darkTheme)
            swipe(Pair(200.0, 450.0), Pair(200.0, 100.0))
            enterText(AdRequestKeys.contextTagField, "value")
            waitAndClick(AdRequestKeys.contextTagAddBtn)
            enterText(AdRequestKeys.parametersKeyField, "value1")
            enterText(AdRequestKeys.parametersValueField, "value2")
            waitAndClick(AdRequestKeys.parametersTagAddBtn)
            waitAndClick(AdRequestKeys.saveBtn)
            waitAndClick(AppOpenAdKeys.log)
            setAdUnitId(ScreenName.AppOpenAd, MockAdUnits.APP_OPEN)
            waitAndClick(AppOpenAdKeys.loadAd)
            waitLogsCallback(AppOpenAdCallbacks.loaded)
            waitAndClick(AppOpenAdKeys.showAd)
            waitForElement(AppOpenAdKeys.ad)
            assertRequestBody("/v4/ad", Pair("gender", "male"))
            assertRequestBody("/v4/ad", Pair("age", "10"))
            assertRequestBody("/v4/ad", Pair("value1", "value2"))
            assertRequestBody("/v4/ad", Pair("context_query", "contextQuery"))
            assertRequestBody("/v4/ad", Pair("preferred_theme", "dark"))
        })
    }

    @Test
    @TestName("Flutter РСЯ Трекинг в AppOpenAd")
    fun loadBannerTracking() {
        waitAndClick(HomeKeys.appOpenAd)
        waitAndClick(AppOpenAdKeys.log)
        setAdUnitId(ScreenName.AppOpenAd, MockAdUnits.APP_OPEN)
        waitAndClick(AppOpenAdKeys.loadAd)
        waitLogsCallback(AppOpenAdCallbacks.loaded)
        waitAndClick(AppOpenAdKeys.showAd)
        waitForElement(AppOpenAdKeys.ad)
        assertRequest("/count")
        waitAndClick(AppOpenAdKeys.callToAction)
        assertBrowserOpened()
        returnToApp()
        wait(Duration.ofSeconds(5), "Ожидаем продергивания урлов")
        assertRequest("/count")
        assertRequest("/report")
        waitAndClick(AppOpenAdKeys.closeAd)
    }

    @Test
    @TestName("Проверка ассета adtune")
    fun testAppOpenAdAdtune() {
        waitAndClick(HomeKeys.appOpenAd)
        waitAndClick(AppOpenAdKeys.log)
        setAdUnitId(ScreenName.AppOpenAd, MockAdUnits.APP_OPEN)
        waitAndClick(AppOpenAdKeys.loadAd)
        waitLogsCallback(AppOpenAdCallbacks.loaded)
        waitAndClick(AppOpenAdKeys.showAd)
        waitForElement(AppOpenAdKeys.ad)
        waitAndClick(AppOpenAdKeys.feedback, useLocation = true)
//        checkAdtuneVisible()
    }

    @Test
    @TestName("Загрузка креативов при выключенном интернете")
    fun testAppopenadNoNetwork() {
        waitAndClick(HomeKeys.appOpenAd)
        waitAndClick(AppOpenAdKeys.log)
        toggleNetwork(false)
        wait(networkActionDelay, "Ожидаем выключение интернета")
        waitAndClick(AppOpenAdKeys.loadAd)
        waitLogsCallback(CommonCallbacks.noNetworkError)
    }
}
