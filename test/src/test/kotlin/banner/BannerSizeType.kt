package banner

import com.yandex.plugin_tests_support.BaseTest
import com.yandex.plugin_tests_support.enterText
import com.yandex.plugin_tests_support.waitAndClick
import keys.BannerKeys

sealed class BannerSizeType {
    class Inline(val width: Int?, val height: Int?) : BannerSizeType()
    class Sticky(val width: Int?) : BannerSizeType()
}

fun BaseTest.setBannerSizeType(type: BannerSizeType) {
    when (type) {
        is BannerSizeType.Inline -> {
            waitAndClick(BannerKeys.inlineSwitch)
            if (type.width != null) {
                enterText(BannerKeys.width, "${type.width}")
            }
            if (type.height != null) {
                enterText(BannerKeys.height, "${type.height}")
            }
        }
        is BannerSizeType.Sticky -> {
            waitAndClick(BannerKeys.stickySwitch)
            if (type.width != null) {
                enterText(BannerKeys.width, "${type.width}")
            }
        }
    }
}
