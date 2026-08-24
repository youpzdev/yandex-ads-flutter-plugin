package smoke_tests

import banner.BannerSizeType
import banner.setBannerSizeType
import callbacks.BannerCallbacks
import callbacks.CommonCallbacks
import com.yandex.plugin_tests_support.TestName
import com.yandex.plugin_tests_support.assertBrowserOpened
import com.yandex.plugin_tests_support.assertRequest
import com.yandex.plugin_tests_support.assertRequestBody
import com.yandex.plugin_tests_support.backgroundApp
import com.yandex.plugin_tests_support.clearSnifferLog
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
import keys.AdRequestKeys
import keys.BannerKeys
import keys.CommonKeys
import keys.HomeKeys
import org.openqa.selenium.By
import org.testng.annotations.DataProvider
import org.testng.annotations.Ignore
import org.testng.annotations.Test
import support.Constants.scrollActionDelay
import support.Constants.networkActionDelay
import support.MockAdUnits
import support.ScreenName
import support.checkAdtuneVisible
import support.checkCallbackNotAppeared
import support.safelyAssertAdLoaded
import support.setAdUnitId
import support.waitLogsCallback
import java.time.Duration

@Epic("E2E тесты")
class BannerTests: BaseFlutterTest() {

    @DataProvider(name = "sizeTypeProvider")
    fun sizeTypes(): Array<BannerSizeType> {
        return arrayOf(
            BannerSizeType.Inline(MockAdUnits.BANNER_WIDTH, MockAdUnits.BANNER_HEIGHT),
            BannerSizeType.Sticky(null)
        )
    }

    @DataProvider(name = "sizeTypeProviderParametersTests")
    fun sizeTypesParametersTest(): Array<BannerSizeType> {
        return arrayOf(
            BannerSizeType.Inline(MockAdUnits.BANNER_WIDTH, MockAdUnits.BANNER_HEIGHT),
            BannerSizeType.Sticky(null)
        )
    }

    @Test(dataProvider = "sizeTypeProvider")
    @TestName("Загрузка и клик по баннеру")
    fun loadStickyBannerAdAndClick(sizeType: BannerSizeType) {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setBannerSizeType(sizeType)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitAndClick(BannerKeys.banner)
        assertBrowserOpened()
        returnToApp()
        listOf(
            BannerCallbacks.clicked,
            BannerCallbacks.impression,
        ).forEach { callback -> waitLogsCallback(callback) }
    }

    @Test
    @TestName("Загрузка и клик по Inline баннеру")
    fun loadInlineBannerAdAndClick() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setBannerSizeType(BannerSizeType.Inline(MockAdUnits.BANNER_WIDTH, MockAdUnits.BANNER_HEIGHT))
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitAndClick(BannerKeys.banner)
        assertBrowserOpened()
        returnToApp()
        listOf(
            BannerCallbacks.clicked,
            BannerCallbacks.impression,
        ).forEach { callback -> waitLogsCallback(callback) }
    }

    @Test
    @TestName("Загрузка и клик по Sticky баннеру")
    fun loadStickyBannerAdAndClick() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        waitAndClick(BannerKeys.stickySwitch)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitAndClick(BannerKeys.banner)
        assertBrowserOpened()
        returnToApp()
        listOf(
            BannerCallbacks.loaded,
            BannerCallbacks.impression,
            BannerCallbacks.clicked,
        ).forEach { callback -> waitLogsCallback(callback) }
    }

    @Test
    @TestName("Banner: Сворачивание приложения")
    fun loadBannerAdAndHide() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        waitAndClick(BannerKeys.stickySwitch)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        backgroundApp(Duration.ofSeconds(10), true)
        waitForElement(BannerKeys.banner)
    }

    @Test
    @TestName("Banner: Перезагрузка баннера")
    fun reloadBannerAd() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitAndClick(CommonKeys.logClear)
        checkCallbackNotAppeared(BannerCallbacks.loaded, Duration.ofSeconds(3))
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
    }

    @Test
    @TestName("Banner: Загрузка рекламы с некорректным блоком")
    fun loadAppOpenInvalidAd() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setAdUnitId(ScreenName.Banner, "adlib12963-b-999")
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.notExist)
    }

    @Test
    @TestName("Flutter Блокировка приложения")
    fun loadBannerAdAndBlock() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitForElement(BannerKeys.banner)
        temporarilyLockScreen(Duration.ofSeconds(10))
        waitForElement(BannerKeys.banner)
    }

    @Test(dataProvider = "sizeTypeProviderParametersTests")
    @TestName("Flutter Banner Загрузка рекламы с установленными параметрами")
    fun loadBannerParameters(sizeType: BannerSizeType) {
        waitAndClick(HomeKeys.bannerPage)
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
            wait(scrollActionDelay, "Ожидаем завершения скролла")
            enterText(AdRequestKeys.contextTagField, "value1,value2,value3")
            waitAndClick(AdRequestKeys.contextTagAddBtn)
            enterText(AdRequestKeys.parametersKeyField, "value1")
            enterText(AdRequestKeys.parametersValueField, "value2")
            waitAndClick(AdRequestKeys.parametersTagAddBtn)
            waitAndClick(AdRequestKeys.saveBtn)
            setBannerSizeType(sizeType)
            waitAndClick(BannerKeys.log)
            setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
            waitAndClick(BannerKeys.loadAd)
            waitLogsCallback(BannerCallbacks.loaded)
            waitForElement(BannerKeys.banner)
            assertRequestBody("/v4/ad", Pair("gender", "male"))
            assertRequestBody("/v4/ad", Pair("age", "10"))
            assertRequestBody("/v4/ad", Pair("value1", "value2"))
            assertRequestBody("/v4/ad", Pair("context_query", "contextQuery"))
            assertRequestBody("/v4/ad", Pair("preferred_theme", "dark"))
        })
    }

    @Test(dataProvider = "sizeTypeProviderParametersTests")
    @TestName("Flutter Загрузка рекламы при выключенном интернете")
    fun loadBannerNoInternet(sizeType: BannerSizeType) {
        platformDependant(ios = {
            toggleNetwork(false)
            waitAndClick(HomeKeys.bannerPage)
            waitAndClick(BannerKeys.log)
            setBannerSizeType(sizeType)
            setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
            waitAndClick(BannerKeys.loadAd)
            waitLogsCallback(BannerCallbacks.notLoaded)
            toggleNetwork(true)
            waitAndClick(BannerKeys.loadAd)
            waitLogsCallback(BannerCallbacks.loaded)
            waitForElement(BannerKeys.banner)
        })
    }

    @Test
    @TestName("Flutter РСЯ Трекинг в banner рекламе")
    fun loadBannerTracking() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setBannerSizeType(BannerSizeType.Inline(MockAdUnits.BANNER_WIDTH, MockAdUnits.BANNER_HEIGHT))
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        assertRequest("/2")
        clearSnifferLog()
//        platformDependant(ios = {
//            waitAndClick(CommonKeys.callToAction)
//        }, android = {
//            wait(Duration.ofSeconds(3), "Ожидаем загрузки видео в рекламе")
//            waitAndClick(BannerKeys.videoCta, useLocation = true)
//        })
//        assertBrowserOpened()
//        returnToApp()
//        assertRequest("/tracking/")
//        assertRequest("/report/falseclick/")
//        clearSnifferLog()
//        platformDependant(ios = {
//            waitAndClick(CommonKeys.callToAction)
//        }, android = {
//            wait(Duration.ofSeconds(3), "Ожидаем загрузки видео в рекламе")
//            waitAndClick(BannerKeys.videoCta, useLocation = true)
//        })
//        assertBrowserOpened()
//        returnToApp()
//        wait(Duration.ofSeconds(3), "Ожидаем повторного продергивания урлов")
//        assertRequest("/tracking/")
//        assertRequest("/report/falseclick/")
    }

    @Test
    @TestName("Трекинг dsp")
    fun testDspStickyTracking() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        waitAndClick(BannerKeys.stickySwitch)
        enterText(BannerKeys.width, MockAdUnits.BANNER_WIDTH.toString())
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER_DSP)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitForElement(BannerKeys.banner)
        assertRequest("/render")
        assertRequest("/1")
        waitAndClick(BannerKeys.banner)
        returnToApp()
        assertRequest("/click")
    }

    @Test
    @TestName("Трекинг dsp")
    fun testDspInlineTracking() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        waitAndClick(BannerKeys.inlineSwitch)
        enterText(BannerKeys.width, MockAdUnits.BANNER_WIDTH.toString())
        enterText(BannerKeys.height, MockAdUnits.BANNER_HEIGHT.toString())
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER_DSP)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        assertRequest("/render")
        assertRequest("/1")
        waitForElement(BannerKeys.banner)
        waitAndClick(BannerKeys.banner)
        assertBrowserOpened()
        returnToApp()
        assertRequest("/click")
    }

    @Test
    @TestName("Проверка ассета adtune")
    fun testBannerAdtune() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        setBannerSizeType(BannerSizeType.Inline(MockAdUnits.BANNER_WIDTH, MockAdUnits.BANNER_HEIGHT))
        setAdUnitId(ScreenName.Banner, MockAdUnits.BANNER)
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(BannerCallbacks.loaded)
        waitAndClick(CommonKeys.feedback)
        checkAdtuneVisible()
    }

    @Test
    @TestName("Загрузка креативов при выключенном интернете")
    fun testStickyNoNetwork() {
        waitAndClick(HomeKeys.bannerPage)
        waitAndClick(BannerKeys.log)
        toggleNetwork(false)
        wait(networkActionDelay, "Ожидаем выключение интернета")
        waitAndClick(BannerKeys.loadAd)
        waitLogsCallback(CommonCallbacks.noNetworkError)
    }
}
