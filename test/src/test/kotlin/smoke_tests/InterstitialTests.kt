package smoke_tests

import callbacks.CommonCallbacks
import callbacks.InterstitialCallbacks
import com.yandex.plugin_tests_support.ScreenElement
import com.yandex.plugin_tests_support.TestName
import com.yandex.plugin_tests_support.assertRequest
import com.yandex.plugin_tests_support.assertRequestBody
import io.qameta.allure.Epic
import keys.HomeKeys
import keys.InterstitialKeys
import org.testng.annotations.Test
import com.yandex.plugin_tests_support.returnToApp
import com.yandex.plugin_tests_support.waitAndClick
import com.yandex.plugin_tests_support.backgroundApp
import com.yandex.plugin_tests_support.clearSnifferLog
import com.yandex.plugin_tests_support.enterText
import com.yandex.plugin_tests_support.platformDependant
import com.yandex.plugin_tests_support.screenCenter
import com.yandex.plugin_tests_support.swipe
import com.yandex.plugin_tests_support.temporarilyLockScreen
import com.yandex.plugin_tests_support.toggleNetwork
import com.yandex.plugin_tests_support.wait
import com.yandex.plugin_tests_support.waitForElement
import keys.AdRequestKeys
import keys.AppOpenAdKeys
import keys.CommonKeys
import org.testng.annotations.DataProvider
import support.MockAdUnits
import support.*
import support.Constants.scrollActionDelay
import support.Constants.networkActionDelay
import java.time.Duration

@Epic("E2E тесты")
class InterstitialTests: BaseFlutterTest() {

    @DataProvider(name = "demoBlocksProvider")
    fun demoBlocks(): Array<String> {
        return arrayOf(
            MockAdUnits.INTERSTITIAL,
        )
    }

    @DataProvider(name = "demoDspProvider")
    fun demoDspBlocks(): Array<String> {
        return arrayOf(
            MockAdUnits.INTERSTITIAL_DSP,
        )
    }

    @Test
    @TestName("Загрузка, клик и закрытие Interstitial рекламы")
    fun loadInterstitialAdAndClick() {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, MockAdUnits.INTERSTITIAL)
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(InterstitialCallbacks.loaded)
        waitAndClick(InterstitialKeys.showAd)
        waitForElement(InterstitialKeys.ad)
        waitAndClick(InterstitialKeys.callToAction)
//        assertBrowserOpened()
        returnToApp()
        clickSkipButtonIfPresent()
        waitAndClick(InterstitialKeys.closeAd)
        listOf(
            InterstitialCallbacks.shown,
            InterstitialCallbacks.clicked,
            InterstitialCallbacks.impression,
            InterstitialCallbacks.dismissed
        ).forEach { callback -> waitLogsCallback(callback) }
    }

    @Test
    @TestName("Interstitial: Сворачивание приложения")
    fun loadInterstitialAdAndHide() {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, MockAdUnits.INTERSTITIAL)
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(InterstitialCallbacks.loaded)
        waitAndClick(InterstitialKeys.showAd)
        backgroundApp(Duration.ofSeconds(10), true)
//        waitForElement(InterstitialKeys.ad)
    }

    @Test
    @TestName("Interstitial: Загрузка рекламы с некорректным блоком")
    fun loadInterstitialInvalidAd() {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, "adlib9475-i-999")
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(InterstitialCallbacks.notExist)
    }

    @Test(dataProvider = "demoBlocksProvider")
    @TestName("Flutter РСЯ. Отображение в landscape")
    fun loadDemoBanner(adUnitId: String) {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, adUnitId)
        waitAndClick(InterstitialKeys.loadAd)
        safelyAssertAdLoaded(ScreenName.Interstitial)
        waitAndClick(InterstitialKeys.showAd)
//        waitForElement(InterstitialKeys.ad)
    }

    @Test
    @TestName("Flutter Блокировка приложения")
    fun loadInterstitialAdAndBlock() {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, MockAdUnits.INTERSTITIAL)
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(InterstitialCallbacks.loaded)
        waitAndClick(InterstitialKeys.showAd)
        waitForElement(InterstitialKeys.ad)
        temporarilyLockScreen(Duration.ofSeconds(10))
        waitForElement(InterstitialKeys.ad)
        clickSkipButtonIfPresent()
        waitAndClick(InterstitialKeys.closeAd)
        waitLogsCallback(InterstitialCallbacks.impression)
    }

    @Test
    @TestName("Flutter Interstitial Загрузка рекламы с установленными параметрами")
    fun loadInterstitialParameters() {
        waitAndClick(HomeKeys.interstitialPage)
        platformDependant(ios = {
            waitAndClick(InterstitialKeys.log)
            waitAndClick(CommonKeys.adRequest)
            waitForElement(AdRequestKeys.contextQueryField)
            swipe(Pair(200.0, 500.0), Pair(200.0, 200.0))
            enterText(AdRequestKeys.ageField, "10")
            enterText(AdRequestKeys.contextQueryField, "contextQuery")
            enterText(AdRequestKeys.genderField, "male")
            waitAndClick(AdRequestKeys.themeField)
            waitAndClick(AdRequestKeys.darkTheme)
            swipe(Pair(200.0, 450.0), Pair(200.0, 100.0))
            wait(scrollActionDelay, "Ожидаем завершения скролла")
            enterText(AdRequestKeys.contextTagField, "value1,value2,value3")
            waitAndClick(AdRequestKeys.contextTagAddBtn)
            enterText(AdRequestKeys.parametersKeyField, "value1")
            enterText(AdRequestKeys.parametersValueField, "value2")
            waitAndClick(AdRequestKeys.parametersTagAddBtn)
            waitAndClick(AdRequestKeys.saveBtn)
            setAdUnitId(ScreenName.Interstitial, MockAdUnits.INTERSTITIAL)
            waitAndClick(InterstitialKeys.loadAd)
            waitLogsCallback(InterstitialCallbacks.loaded)
            waitAndClick(InterstitialKeys.showAd)
            waitForElement(InterstitialKeys.ad)
            assertRequestBody("/v4/ad", Pair("gender", "male"))
            assertRequestBody("/v4/ad", Pair("age", "10"))
            assertRequestBody("/v4/ad", Pair("value1", "value2"))
            assertRequestBody("/v4/ad", Pair("context_query", "contextQuery"))
            assertRequestBody("/v4/ad", Pair("preferred_theme", "dark"))
        })
    }

    @Test
    @TestName("Flutter РСЯ Трекинг в interstitial рекламе")
    fun loadInterstitialTracking() {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, MockAdUnits.INTERSTITIAL)
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(InterstitialCallbacks.loaded)
        waitAndClick(InterstitialKeys.showAd)
        waitForElement(InterstitialKeys.ad)
        assertRequest("/2")
        try {
            waitAndClick(InterstitialKeys.callToAction)
        } catch (err: AssertionError) {
            waitAndClick(ScreenElement.WithCoordinates(screenCenter, "рекламу"))
        }
        returnToApp()
        assertRequest("/falseclick")
        clearSnifferLog()
        try {
            waitAndClick(InterstitialKeys.callToAction)
        } catch (err: AssertionError) {
            waitAndClick(ScreenElement.WithCoordinates(screenCenter, "рекламу"))
        }
        returnToApp()
        assertRequest("/falseclick")
    }

    @Test(dataProvider = "demoDspProvider")
    @TestName("Трекинг dsp")
    fun testInterstitialDspTracking(adUnitId: String) {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, adUnitId)
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(InterstitialCallbacks.loaded)
        waitAndClick(InterstitialKeys.showAd)
        assertRequest("/1")
        waitAndClick(ScreenElement.WithCoordinates(screenCenter, "рекламу"))
        returnToApp()
        assertRequest("/report/click")
    }

    @Test
    @TestName("Проверка ассета adtune")
    fun testInterstitialAdtune() {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        setAdUnitId(ScreenName.Interstitial, MockAdUnits.INTERSTITIAL)
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(InterstitialCallbacks.loaded)
        waitAndClick(InterstitialKeys.showAd)
//        waitForElement(InterstitialKeys.ad)
        waitAndClick(InterstitialKeys.feedback)
        checkAdtuneVisible()
    }

    @Test
    @TestName("Загрузка креативов при выключенном интернете")
    fun testInterstitialNoNetwork() {
        waitAndClick(HomeKeys.interstitialPage)
        waitAndClick(InterstitialKeys.log)
        toggleNetwork(false)
        wait(networkActionDelay, "Ожидаем выключение интернета")
        waitAndClick(InterstitialKeys.loadAd)
        waitLogsCallback(CommonCallbacks.noNetworkError)
    }
}
