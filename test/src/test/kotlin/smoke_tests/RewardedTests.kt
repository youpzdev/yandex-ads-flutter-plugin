package smoke_tests

import callbacks.CommonCallbacks
import callbacks.RewardedCallbacks
import com.yandex.plugin_tests_support.TestName
import io.qameta.allure.Epic
import keys.HomeKeys
import keys.RewardedKeys
import org.testng.annotations.Test
import com.yandex.plugin_tests_support.assertBrowserOpened
import com.yandex.plugin_tests_support.assertRequest
import com.yandex.plugin_tests_support.returnToApp
import com.yandex.plugin_tests_support.clearSnifferLog
import com.yandex.plugin_tests_support.waitAndClick
import com.yandex.plugin_tests_support.backgroundApp
import com.yandex.plugin_tests_support.enterText
import com.yandex.plugin_tests_support.isPngEquals
import com.yandex.plugin_tests_support.platformDependant
import com.yandex.plugin_tests_support.swipe
import com.yandex.plugin_tests_support.temporarilyLockScreen
import com.yandex.plugin_tests_support.toggleNetwork
import com.yandex.plugin_tests_support.wait
import com.yandex.plugin_tests_support.waitForElement
import keys.AdRequestKeys
import keys.CommonKeys
import keys.InterstitialKeys
import org.testng.annotations.DataProvider
import support.MockAdUnits
import support.*
import support.Constants.scrollActionDelay
import support.Constants.networkActionDelay
import java.time.Duration

@Epic("E2E тесты")
class RewardedTests: BaseFlutterTest() {

    @DataProvider(name = "demoBlocksProvider")
    fun demoBlocks(): Array<String> {
        return arrayOf(
            MockAdUnits.REWARDED,
        )
    }

    @Test
    @TestName("Flutter Загрузка, клик и закрытие Rewarded рекламы")
    fun loadRewardedAdAndClick() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED)
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.loaded)
        waitAndClick(RewardedKeys.showAd)
//        waitForElement(RewardedKeys.ad)
//        waitAndClick(RewardedKeys.callToAction)
//        assertBrowserOpened()
//        returnToApp()
//        waitAndClick(RewardedKeys.closeAd)
//        listOf(
//            RewardedCallbacks.shown,
//            RewardedCallbacks.clicked,
//            RewardedCallbacks.impression,
//            RewardedCallbacks.dismissed
//        ).forEach { callback -> waitLogsCallback(callback) }
    }

    @Test
    @TestName("Rewarded: Сворачивание приложения")
    fun loadRewardedAdAndHide() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED)
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.loaded)
        waitAndClick(RewardedKeys.showAd)
        backgroundApp(Duration.ofSeconds(10), true)
        //waitForElement(RewardedKeys.ad)
    }

    @Test
    @TestName("Rewarded: Загрузка рекламы с некорректным блоком")
    fun loadAppOpenInvalidAd() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, "adlib2892-r-999")
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.notExist)
    }

    @Test(dataProvider = "demoBlocksProvider")
    @TestName("Flutter РСЯ. Отображение Rewarded рекламы в AdRequest в landscape")
    fun loadDemoBanner(adUnitId: String) {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, adUnitId)
        waitAndClick(RewardedKeys.loadAd)
        safelyAssertAdLoaded(ScreenName.Rewarded)
        waitAndClick(RewardedKeys.showAd)
        waitForElement(RewardedKeys.ad)
    }

    @Test
    @TestName("Flutter Блокировка приложения")
    fun loadRewardedAdAndBlock() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED)
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.loaded)
        waitAndClick(RewardedKeys.showAd)
//        waitForElement(RewardedKeys.ad)
        temporarilyLockScreen(Duration.ofSeconds(10))
//        waitForElement(RewardedKeys.ad)
//        waitAndClick(RewardedKeys.closeAd)
//        waitLogsCallback(RewardedCallbacks.impression)
    }

    @Test
    @TestName("Flutter РСЯ. Закрытие рекламы до получения награды")
    fun loadRewardedAdAndClose() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED)
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.loaded)
        waitAndClick(RewardedKeys.showAd)
        waitForElement(RewardedKeys.ad)
        //waitAndClick(RewardedKeys.closeAd)
        //checkCallbackNotAppeared(RewardedCallbacks.impression)
    }

    @Test
    @TestName("Flutter Rewarded Загрузка рекламы с установленными параметрами")
    fun loadRewardedParameters() {
        platformDependant(ios = {
            waitAndClick(HomeKeys.rewardedPage)
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
            setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED)
            waitAndClick(RewardedKeys.log)
            waitAndClick(RewardedKeys.loadAd)
            waitLogsCallback(RewardedCallbacks.loaded)
            waitAndClick(RewardedKeys.showAd)
            waitForElement(RewardedKeys.ad)
//            assertRequestBody("/v4/ad", Pair("gender", "male"))
//            assertRequestBody("/v4/ad", Pair("age", "10"))
//            assertRequestBody("/v4/ad", Pair("value1", "value2"))
//            assertRequestBody("/v4/ad", Pair("context_query", "contextQuery"))
//            assertRequestBody("/v4/ad", Pair("preferred_theme", "dark"))
        })
    }

    @Test
    @TestName("Flutter. РСЯ Трекинг в rewarded рекламе")
    fun loadRewardedTracking() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED)
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.loaded)
        waitAndClick(RewardedKeys.showAd)
    }

    @Test
    @TestName("Отображение dsp")
    fun testRewardedDspTracking() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED_DSP)
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.loaded)
        waitAndClick(RewardedKeys.showAd)
        assertRequest("/1")
    }

    @Test
    @TestName("Проверка ассета adtune")
    fun loadRewardedAdtune() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        setAdUnitId(ScreenName.Rewarded, MockAdUnits.REWARDED_ADTUNE)
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(RewardedCallbacks.loaded)
        waitAndClick(RewardedKeys.showAd)
//        waitForElement(RewardedKeys.ad)
//        waitAndClick(CommonKeys.feedback, useLocation = true)
//        checkAdtuneVisible()
    }

    @Test
    @TestName("Загрузка креативов при выключенном интернете")
    fun testRewardedNoNetwork() {
        waitAndClick(HomeKeys.rewardedPage)
        waitAndClick(RewardedKeys.log)
        toggleNetwork(false)
        wait(networkActionDelay, "Ожидаем выключение интернета")
        waitAndClick(RewardedKeys.loadAd)
        waitLogsCallback(CommonCallbacks.noNetworkError)
    }
}
