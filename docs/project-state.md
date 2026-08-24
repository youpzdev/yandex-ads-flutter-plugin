# Состояние проекта

Актуально на 2026-08-24.

## Цель

Создать поддерживаемый форк Flutter-плагина Yandex Mobile Ads 8.3.0 с совместимым базовым API, исправленным жизненным циклом рекламы, управляемым обновлением баннеров и Native Ads на Android и iOS.

## Канонические источники

- Текущее состояние, границы и этапы: этот файл.
- Все архитектурные и контрактные решения: [decision-log.md](decision-log.md).
- Upstream Git: `https://github.com/yandexmobile/yandex-ads-flutter-plugin`, commit `e27bebb8365a320e0cadedf59ffa8d24d5d6f7b1`.
- Исходный пакет: архив `yandex_mobileads 8.3.0` с pub.dev, временно распакован в `.work/upstream-8.3.0`.

## Утверждённый объём

- Перенести опубликованный исходник плагина в корень репозитория и сохранить оба наблюдаемых лицензионных источника без самовольного толкования.
- Исправить ожидание platform-channel операций, завершение pending-загрузок, отмену, timeout и идемпотентное освобождение ресурсов.
- Упростить публичное использование без поломки совместимых сценариев upstream 8.3.0.
- Добавить управляемое автообновление баннеров: только во время видимого и допустимого показа, без параллельных запросов и с постоянным размером placement.
- Добавить Native Ads для Android и iOS с единым Flutter-контрактом.
- Добавить автоматические проверки Dart, Android и доступные проверки iOS; реальные рекламные ответы и iOS runtime не считать проверенными без устройств и macOS/Xcode.

## Ограничения

- Нативные Yandex Mobile Ads SDK остаются внешними зависимостями; форк не подменяет рекламный движок и не исправляет сторонние mediation SDK.
- Публичная публикация форка заблокирована до разрешения конфликта: pub.dev-архив содержит Apache 2.0, официальный GitHub содержит отдельное ограничительное соглашение Yandex Mobile Ads SDK.
- Production ad unit ID, искусственные показы и клики в репозиторий не добавляются.
- Публичные breaking changes не принимаются молча: сначала решение в журнале, затем реализация.
- Временные архивы, фикстуры и диагностические материалы живут только в `.work/` и не смешиваются с продуктовым кодом.

## Реализовано

- Исходник опубликованного пакета 8.3.0 перенесён в корень с сохранением отдельного Apache-текста для glue-кода и GitHub EULA.
- Инициализация SDK повторяется после ошибки; загрузчики full-screen форматов имеют единый timeout на инициализацию, создание и native request, отменяют pending operation и освобождаются идемпотентно.
- Managed banner refresh имеет пресеты `conservative` 120 секунд, `standard` 60 секунд и `engaged` 30 секунд. Время считается только при видимом placement и состоянии приложения `resumed`; интервал и retry меньше 30 секунд запрещены.
- Native Ads реализованы на Android и iOS через `<native-ad>` PlatformView, per-view method/event channels, SDK-bound assets и шаблоны `compact`/`media`. Минимумы — 324×344 и 324×364 соответственно; media не уже 300 и не ниже 160.
- Native load имеет timeout, `cancelLoading`, generation guard и очередь событий до готовности EventChannel. Поздний callback не показывает creative после отмены.
- Добавлены светлый, тёмный и контрастный brand-safe стилевые пресеты.

## Этап

Реализация, независимый review и доступная локальная верификация завершены. Изменения фиксируются логическими локальными Git-коммитами; публикация пакета, внешний push и device release-smoke в этот этап не входят.

## Проверка на текущем этапе

- `flutter pub get`: пройдено на Flutter 3.44.4 / Dart 3.12.2.
- `flutter analyze`: пройдено без замечаний после реализации.
- `flutter test test/dart/ad_lifecycle_contract_test.dart`: 8/8 пройдено; покрыты retry и timeout loader, cancel/destroy pending operation и безопасные пресеты.
- Android Native API сверен через `javap` с точным `mobileads-8.3.0.aar`. Example переведён на `path: ../`; `flutter build apk --debug` успешно собрал текущий форк в `example/build/app/outputs/flutter-apk/app-debug.apk` (188959343 байта). Изолированный plugin-модуль без Flutter embedding по-прежнему не используется как критерий.
- iOS API сверен с headers SDK 8.3.0. Swift type-check, Xcode build и iOS runtime на Windows не выполнялись.
- Example содержит экраны Native Ads и managed banner с безопасными пресетами и официальным test unit `demo-native-content-yandex`.
- Реальный Android/iOS placement, рекламный ответ, impression/click и integration indicator требуют device smoke-test; успешная APK-сборка их не доказывает.
