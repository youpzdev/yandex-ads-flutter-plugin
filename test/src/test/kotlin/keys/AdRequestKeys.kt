package keys

import com.yandex.plugin_tests_support.AndroidElementId
import com.yandex.plugin_tests_support.ScreenElement

object AdRequestKeys {
    val ageField = ScreenElement.WithId("age-field", "текстовое поле Age")
    val contextQueryField = ScreenElement.WithId("context-query-field", "текстовое поле Context query")
    val genderField = ScreenElement.WithId("gender-field", "текстовое поле Gender")
    val themeField = ScreenElement.WithId("theme-field", "пикер Preferred theme")
    val contextTagField = ScreenElement.WithId("context-tag-field", "текстовое поле New Context Tag")
    val contextTagAddBtn = ScreenElement.WithId("context-tag-add-btn", "кнопку плюс у New Context Tag")
    val parametersKeyField = ScreenElement.WithId("parameters-key-field", "текстовое поле Key")
    val parametersValueField = ScreenElement.WithId("parameters-value-field", "текстовое поле Value")
    val parametersTagAddBtn = ScreenElement.WithId("parameters-add-btn", "кнопку плюс у Parameters")
    val saveBtn = ScreenElement.WithId("save-btn", "кнопку Save")
    val darkTheme = ScreenElement.WithId("dark", AndroidElementId.ContentDesc("dark"), "тему dark", isNative = false)
}
