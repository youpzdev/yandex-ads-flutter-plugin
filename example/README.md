# Yandex Advertising Network Mobile

This app is the executable consumer sample for the local maintained fork. Its
`pubspec.yaml` intentionally resolves `yandex_mobileads` from `../`, so
`flutter pub get` and Android builds exercise the source in this repository
rather than the package hosted on pub.dev.

The example is set to Android API 36 / Android Gradle Plugin 8.11.1 because
its current AndroidX dependencies require that toolchain level.
On Windows the sample disables Kotlin incremental compilation: its Dart package
cache and the project may live on different drive roots, which breaks Kotlin's
relocatable incremental cache.

It demonstrates upstream banner, interstitial, rewarded and app-open formats,
plus the fork additions:

- **Managed banner refresh** — presets `conservative` (120 seconds),
  `standard` (60 seconds), and `engaged` (30 seconds). Refresh counts only
  visible foreground time and avoids overlapping loads.
- **Native ads** — compact and media templates with their enforced safe
  minimum sizes (324 × 344 and 324 × 364), plus `light`, `dark`, and
  `brandSafe` style presets. The sample loads only
  `demo-native-content-yandex`, Yandex's official test placement; replace it
  with a real placement before publishing an app.

Native layouts are SDK-bound: required assets and user clicks remain managed by
the Yandex SDK. The sample does not issue clicks programmatically.

## Documentation
Documentation could be found at the [official website] [DOCUMENTATION]

## License
EULA is available at [EULA website] [LICENSE]

[DOCUMENTATION]: https://yandex.com/dev/mobile-ads/doc/intro/about.html
[LICENSE]: https://yandex.com/legal/mobileads_sdk_agreement/
