# yandex_mobileads — форк

Форк Flutter-плагина для Yandex Mobile Ads SDK 8.3.0.

English: [README.md](README.md)

API оригинала продолжает работать. Сверху форк чинит жизненный цикл рекламы,
добавляет предзагрузку и контроль частоты для полноэкранных форматов, добавляет
Native Ads для Android и iOS и отдаёт все рекламные события одним потоком.

## Установка

На pub.dev форк не публикуется — почему, написано в разделе
[Лицензия](#лицензия). Подключайте по пути или из git:

```yaml
dependencies:
  yandex_mobileads:
    path: ../yandex-mobile-ads-fork
```

Нужен Flutter 3.27 или новее.

## Быстрый старт

```dart
await YandexAds.initialize();
```

### Баннер

Сначала виджет в дереве, потом загрузка. `load` ждёт, пока нативная сторона
примет запрос, поэтому виджет должен быть на экране; если он так и не появился,
загрузка падает с `TimeoutException` по истечении `timeout` (по умолчанию 30
секунд), а не висит вечно.

```dart
final banner = BannerAd(adSize: const BannerAdSize.sticky(width: 320));

// в build():
AdWidget(bannerAd: banner)

await banner.load(const AdRequest(adUnitId: 'demo-banner-yandex'));
await banner.destroy();
```

Второй одновременный `load` на том же баннере бросает `StateError`.

### Баннер с автообновлением

`ManagedBannerAdController` перезагружает баннер только пока он реально на
экране, а приложение — на переднем плане.

```dart
final controller = ManagedBannerAdController(
  adSize: const BannerAdSize.inline(width: 320, maxHeight: 100),
  adRequest: const AdRequest(adUnitId: 'demo-banner-yandex'),
  refreshPolicy: ManagedBannerRefreshPolicy.standard, // 60 секунд
);

// в build():
ManagedBannerAdWidget(controller: controller)
```

Видимость считается как доля площади на экране с учётом окна и всех скроллов
над баннером. Отсчёт интервала идёт только выше `visibilityThreshold` (по
умолчанию 0.5). Контроллер отдаёт `visibleFraction`, `viewableDuration` и
`requestCount`.

### Полноэкранная реклама

`FullscreenAdPool` держит interstitial, rewarded или app-open загруженными,
чтобы показ не начинался с похода в сеть.

```dart
final pool = FullscreenAdPool.interstitial(
  adRequest: const AdRequest(adUnitId: 'demo-interstitial-yandex'),
  capacity: 2,
  frequencyGate: AdFrequencyGate(policy: AdFrequencyPolicy.standard),
);

await pool.start();

final outcome = await pool.showNext(waitFor: const Duration(seconds: 3));
switch (outcome.status) {
  case AdShowStatus.shown:        // outcome.duration, outcome.reward
  case AdShowStatus.blocked:      // outcome.frequency: причина и сколько ждать
  case AdShowStatus.unavailable:  // готовой рекламы не оказалось
  case AdShowStatus.alreadyShowing:
  case AdShowStatus.failed:       // outcome.error
}

await pool.destroy();
```

Пул сам вешает listener, показывает рекламу, ждёт закрытия и уничтожает
объявление — потерять показанную рекламу невозможно. Если плейсмент хочет
владеть объявлением сам, есть `acquire`, но тогда уничтожать его должен он.

Что ещё делает пул:

* следит, чтобы одновременно показывалась только одна полноэкранная реклама —
  в пределах одного движка Flutter, включая прямой вызов `show()`; одно
  объявление нельзя показать дважды;
* заменяет протухшие объявления (`timeToLive`), повторяет неудачные запросы с
  растущей задержкой и разбросом (`AdRetryPolicy`) и ставит повторы на паузу,
  пока приложение в фоне;
* когда бюджет попыток исчерпан, переходит в `FullscreenAdPoolStatus.exhausted`
  и ждёт `retry()`;
* выбрасывает объявления, запрошенные до того, как `setUserConsent`,
  `setAgeRestricted` или `setLocationTracking` изменили настройки таргетинга,
  и отказывает в показе, если настройки сменились до `show()`.

### Частота показов

`AdFrequencyPolicy` ограничивает, как часто может появляться полноэкранная
реклама: минимальный интервал, скользящие лимиты в час и в сутки, лимит на
сессию и пауза после старта. Пресеты: `conservative`, `standard`, `engaged`,
`unlimited`.

```dart
final gate = AdFrequencyGate(policy: AdFrequencyPolicy.standard);

if (gate.evaluate().isAllowed) { /* ... */ }
```

Лимит расходует только показ, дошедший до пользователя. Сохраняйте
`gate.toJson()` и восстанавливайте через `AdFrequencyGate.fromJson`, иначе
суточный лимит обнуляется при каждом запуске; внутри только отметки времени
показов и ничего больше.

`durationPenalty` превращает длину рекламы в паузу после неё: с множителем 2
(по умолчанию) 30-секундное видео отодвигает следующий показ на 60 секунд.

### App-open реклама

```dart
final appOpen = AppOpenAdController(
  adRequest: const AdRequest(adUnitId: 'demo-appopenad-yandex'),
  frequencyPolicy: AdFrequencyPolicy.conservative,
);

appOpen.shows.listen((outcome) => print(outcome.status));
await appOpen.start();
```

`start()` возвращается сразу; вызывайте его после того, как известен ответ
пользователя о согласии. Контроллер не покажет рекламу, если приложение было в
фоне меньше `minimumBackgroundDuration` (системный диалог, шаринг), если
пользователь только что кликнул по любой рекламе или если на экране уже есть
другая полноэкранная реклама.

### Нативная реклама

```dart
final nativeAd = NativeAd(
  adRequest: const AdRequest(adUnitId: 'demo-native-content-yandex'),
  width: 324,
  height: 432,
  template: NativeAdTemplate.media,
  style: NativeAdStyle.brandSafe,
);

// в build():
NativeAdWidget(nativeAd: nativeAd)

await nativeAd.load();
await nativeAd.destroy();
```

Ассеты, media, кнопку жалобы и клики связывает сам нативный SDK. Минимальные
размеры контейнера считаются из шаблона и отступов: при стандартном отступе
324 × 412 для `compact` и 324 × 432 для `media`; при другом отступе берите
`minimumWidthFor` и `minimumHeightFor`. Если загруженному креативу всё равно
не хватает места, реклама не показывается, а `onAdFailedToLoad` сообщает
фактически требуемый размер.

Когда Flutter пересоздаёт PlatformView — например, при прокрутке ленты далеко и
обратно — объявление запрашивается заново, не чаще одного раза в
`NativeAd.reloadInterval` (30 секунд).

### События рекламы

```dart
YandexAds.events.listen((event) {
  analytics.log(event.type.name, {
    'format': event.format.name,
    'adUnitId': event.adUnitId,
  });
});
```

Один поток на баннеры, полноэкранные форматы и нативку: загрузки, отказы,
показы, клики, закрытия и награды. События приходят живьём и не буферизуются,
поэтому подписывайтесь до создания первой рекламы. В `impressionData` лежат
данные о доходе — относитесь к ним как к коммерческим. Плагин никуда их не
отправляет.

## Как закрывается реклама

Кнопку закрытия, её таймер и управление звуком рисует сам Yandex Mobile Ads SDK
вместе с креативом. У `InterstitialAd` есть ровно три метода — `getAdInfo`,
`setAdEventListener` и `show`, — поэтому ни плагин, ни настройки рекламного
блока не могут передвинуть кнопку, сократить таймер или убрать обязательный
просмотр.

Выбирать можно формат: app-open закрывается сразу собственной кнопкой возврата,
а interstitial может держать экран столько, сколько идёт креатив. В примере
есть экран, который переключается между обоими предзагруженными форматами —
разницу видно на устройстве. Учтите: app-open продаётся как реклама при
открытии и возврате в приложение, и использовать его как межстраничную посреди
сессии — решение владельца приложения и его рекламной сети.

## Что изменено относительно оригинала

* Все операции ожидаемы и завершаются: `load`, `show`, `cancelLoading`,
  `destroy` и инициализация. Незавершённые загрузки заканчиваются ошибкой,
  отмена и таймауты работают, освобождение ресурсов идемпотентно.
* Android сообщал о неудачном показе как об успешном — константа
  `onAdFailedToShow` содержала чужое имя. Исправлено.
* Загрузка, ответившая после таймаута, больше не оставляет живыми нативное
  объявление и его каналы.
* Загрузка баннера и нативной рекламы больше не висит вечно в ожидании
  виджета, который так и не появился.
* Награда выдаётся один раз за просмотр. Клиентский колбэк вообще не
  доказательство просмотра: ценные награды подтверждайте на своём сервере.
* `mavenLocal()` больше не приоритетнее Google и Maven Central при резолве
  нативного SDK.
* Добавлены `FullscreenAdPool`, `AdFrequencyPolicy`, `AppOpenAdController`,
  `NativeAd`, `ManagedBannerAdController`, `YandexAds.events`.

Полный список — в [CHANGELOG.md](CHANGELOG.md).

## Ограничения и что не проверено

* iOS не компилировался: работа шла на Windows. Swift разобран статически и
  сверен с документацией SDK 8 и официальными примерами, но перед
  использованием нужна сборка в Xcode.
* Android проверен на устройстве: баннеры, app-open и нативка загружаются и
  отображаются на демо-блоках Яндекса, показы фиксируются. Реальный fill и
  доход на боевых блоках не проверялись.
* Перевод системных часов вперёд обнуляет историю частотных лимитов:
  монотонного источника времени у плагина нет.
* Баннер, перекрытый другим виджетом внутри того же экрана, всё ещё считается
  видимым; диалоги и смена маршрута учитываются.
* Версия пакета осталась 8.3.0, как у оригинала. Подключайте по пути или из
  git, чтобы резолв с pub.dev не подменил код молча.

## Лицензия

В архиве опубликованного пакета лежит Apache 2.0, а в официальном репозитории —
отдельное соглашение Yandex Mobile Ads SDK, ограничивающее распространение. Оба
текста сохранены рядом: [LICENSE](LICENSE) и
[LICENSE-PLUGIN-APACHE](LICENSE-PLUGIN-APACHE). Распространять форк или
публиковать его как пакет можно только после того, как этот конфликт разрешён.

Нативный SDK остаётся внешней зависимостью и покрыт
[соглашением Yandex Mobile Ads SDK](https://yandex.com/legal/mobileads_sdk_agreement/).

Инструкции по интеграции, медиации и SKAdNetwork — в [README.md](README.md).
