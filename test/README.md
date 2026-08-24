# Автотесты для Flutter плагина

### Установка Flutter
Перед сборкой сэмпла для тестов нужно установить Flutter SDK:
1. Установить fvm:</br>
```
brew tap leoafarias/fvm
brew install fvm
```
2. Установить Flutter 3.19.6:</br>
```
fvm install 3.19.6
```

### Инспектирование тестового приложения
Для инспектирования UI тестового приложения с целью поиска идентификаторов элементов можно использовать Appium Inspector. Установщик можно найти тут: https://github.com/appium/appium-inspector/releases

Для поиска элементов Flutter понадобится установить UiAutomator2 драйвер:
`appium driver install uiautomator2`
и использовать следующий набор Capabilities (замените {ARCADIA_ROOT} путём к arcadia):
```
{
  "platformName": "Android",
  "appium:automationName": "UiAutomator2",
  "appium:appPackage": "com.yandex.mobile.ads.flutter.example",
  "appium:app": "{ARCADIA_ROOT}/adv/pcode/mobileadssdk/sdk/flutter/internal_test_app/build/app/outputs/flutter-apk/app-release.apk"
}
```

Для поиска элементов Android SDK понадобится установить Espresso драйвер:
`appium driver install espresso`
и использовать следующий набор Capabilities:
```
{
  "platformName": "Android",
  "appium:automationName": "Espresso",
  "appium:appPackage": "com.yandex.mobile.ads.flutter.example",
  "appium:appActivity": "com.yandex.mobile.ads.flutter.example.MainActivity"
}
```

Для поиска элементов в iOS понадобится установить XCUITest драйвер:
`appium driver install xcuitest`
и использовать следующий набор Capabilities:
```
{
  "platformName": "iOS",
  "appium:automationName": "xcuitest",
  "appium:bundleId": "com.yandex.mobile.ads.yandexMobileadsExample"
}
```

### Первый запуск всех тестов из терминала
Открыть терминал из текущей директории (test) и прописать команды `./setup.sh bootstrap-ios` (для iOS) или `./setup.sh bootstrap-android` (для Android)

### Первый запуск тестов из среды
1. Перед первым запуском тестов из среды нужно произвести запуск из терминала, который описан выше.
2. Открыть текущую директорию (test) в IDEA или Android Studio.
3. Выбрать платформу через переменную окружения `PLATFORM` (ios или android) или указать `platform=ios|android` в `local.properties` в текущей директории.
4. Запустить нужный тест через функционал среды, выбрав Gradle-конфигурацию `test` и нужный класс/метод теста:<br/>
![IDE](https://jing.yandex-team.ru/files/stefjen/test.png)

### Повторный запуск тестов
Для тестирования на Android эмуляторах их необходимо запустить перед запуском тестов:<br/>
`./setup.sh start-android-emulators`<br/>
iOS симуляторы запускаются автоматически при запуске тестов, никаких дополнительных действи не требуется.

При изменениях в плагине или сэмпле необходимо произвести повторную сборку приложения:<br/>
`./setup.sh build-ios` для iOS<br/>
`./setup.sh build-apk` для Android

Иногда может потребоваться пересоздание эмуляторов:<br/>
`./setup.sh recreate-simulators` для iOS<br/>
`./setup.sh recreate-android-emulators` для Android

После всех этих действий тесты можно повторно запустить через функционал среды или командами:
`./setup.sh run-all-tests-ios` для iOS<br/>
`./setup.sh run-all-tests-android` для Android


### Написание новых тестов
#### Создание теста
1. Создать новый класс в директории test/src/test/kotlin/smoke_tests, унаследоваться от BaseFlutterTest
2. Добавить тест в файл test/src/test/resources/testng.xml в Suite 1 или Suite 2 (лучше всего распределять равномерно, чтобы тесты отрабатывали быстрее) в `<classes>`:<br />
`<class name="smoke_tests.<Название_теста>" />`
3. Написать в новом классе метод с тестом, указать атрибут @Test

#### Параметризация тестов
Для параметризация тестов необходимо добавить метод, который возвращает массив параметров, с аннотацией @DataProvider. После чего в аннотацию тестового метода @Test добавить аргумент dataProvider. Пример можно посмотреть в тесте `BannerLoadAndClickTest`
