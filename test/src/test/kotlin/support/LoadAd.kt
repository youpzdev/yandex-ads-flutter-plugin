package support

import com.yandex.plugin_tests_support.BaseTest
import com.yandex.plugin_tests_support.allureStep
import com.yandex.plugin_tests_support.getElementContentDescription
import keys.CommonKeys
import org.testng.SkipException
import java.time.Duration
import kotlin.time.TimeSource
import kotlin.time.toKotlinDuration

private val noAdsErrorText = "there are no ads available"

fun BaseTest.safelyAssertAdLoaded(screen: ScreenName) {
    try {
        allureStep("Проверить, что в логах отображается: ${screen.adLoadedCallback()}") {
            val timeSource = TimeSource.Monotonic
            val start = timeSource.markNow()
            while (timeSource.markNow().minus(start) < Duration.ofSeconds(30).toKotlinDuration()) {
                val logs = getElementContentDescription(CommonKeys.logText)
                if (logs.contains(screen.adLoadedCallback())) {
                    return@allureStep
                }
            }

            throw AssertionError("${screen.adLoadedCallback()} not found")
        }
    } catch (err: AssertionError) {
        val logs = getElementContentDescription(CommonKeys.logText)
        if (logs.contains(noAdsErrorText)) {
            throw SkipException("No ads available, skipping")
        } else {
            throw err
        }
    }
}
