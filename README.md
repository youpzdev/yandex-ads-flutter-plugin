# yandex_mobileads — fork

A fork of the Flutter plugin for the Yandex Mobile Ads SDK 8.3.0.

Русская версия: [README.ru.md](README.ru.md)

The upstream API still works. On top of it this fork fixes the ad lifecycle,
adds preloading and pacing for full-screen formats, adds Native Ads for Android
and iOS, and reports every ad event through one stream.

## Install

The fork is not published to pub.dev — see [License](#license). Use a path or a
git dependency:

```yaml
dependencies:
  yandex_mobileads:
    path: ../yandex-mobile-ads-fork
```

Requires Flutter 3.27 or newer.

## Quick start

```dart
await YandexAds.initialize();
```

### Banner

Mount the widget, then load. `load` waits for the native side to accept the
request, so the widget has to be in the tree; it fails with `TimeoutException`
after `timeout` (30 seconds by default) instead of waiting forever.

```dart
final banner = BannerAd(adSize: const BannerAdSize.sticky(width: 320));

// In build():
AdWidget(bannerAd: banner)

await banner.load(const AdRequest(adUnitId: 'demo-banner-yandex'));
await banner.destroy();
```

Overlapping `load` calls on the same banner throw `StateError`.

### Banner that refreshes itself

`ManagedBannerAdController` reloads the banner only while it is really on
screen and the app is in the foreground.

```dart
final controller = ManagedBannerAdController(
  adSize: const BannerAdSize.inline(width: 320, maxHeight: 100),
  adRequest: const AdRequest(adUnitId: 'demo-banner-yandex'),
  refreshPolicy: ManagedBannerRefreshPolicy.standard, // 60 s
);

// In build():
ManagedBannerAdWidget(controller: controller)
```

Visibility is the share of the placement on screen, clipped by the window and
by every scroll view above it. The refresh clock runs only above
`visibilityThreshold` (0.5 by default). The controller also reports
`visibleFraction`, `viewableDuration` and `requestCount`.

### Full-screen ads

`FullscreenAdPool` keeps interstitial, rewarded or app open ads loaded, so a
show does not start with a network round trip.

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
  case AdShowStatus.blocked:      // outcome.frequency explains why and for how long
  case AdShowStatus.unavailable:  // nothing was ready in time
  case AdShowStatus.alreadyShowing:
  case AdShowStatus.failed:       // outcome.error
}

await pool.destroy();
```

The pool sets the listener, shows the ad, waits for the dismissal and destroys
it, so a placement cannot leak a shown ad. Use `acquire` instead if the
placement wants to own the ad itself; then it must destroy it.

Other behaviour worth knowing:

* only one full-screen ad at a time, across every pool and every direct
  `show()` in the process; an ad can also be shown only once;
* stale ads are replaced (`timeToLive`), failed requests are repeated with a
  growing delay and jitter (`AdRetryPolicy`), and retries pause while the app
  is in the background;
* when the retry budget runs out the pool reports
  `FullscreenAdPoolStatus.exhausted` and waits for `retry()`;
* ads requested before `setUserConsent`, `setAgeRestricted` or
  `setLocationTracking` changed the answer are dropped, and an ad whose
  settings changed before `show()` is refused.

### Pacing

`AdFrequencyPolicy` limits how often a full-screen ad may appear: a minimum
gap, rolling hourly and daily caps, a session cap and a startup grace period.
Presets: `conservative`, `standard`, `engaged`, `unlimited`.

```dart
final gate = AdFrequencyGate(policy: AdFrequencyPolicy.standard);

if (gate.evaluate().isAllowed) { /* ... */ }
```

Only shows that reached the user consume a cap. Persist `gate.toJson()` and
restore it with `AdFrequencyGate.fromJson` so daily caps survive a restart; the
payload holds show timestamps and nothing else.

`durationPenalty` turns the length of an ad into a longer gap after it: with
the default factor of 2, a 30 second video pushes the next show 60 seconds
further away.

### App open ads

```dart
final appOpen = AppOpenAdController(
  adRequest: const AdRequest(adUnitId: 'demo-appopenad-yandex'),
  frequencyPolicy: AdFrequencyPolicy.conservative,
);

appOpen.shows.listen((outcome) => print(outcome.status));
await appOpen.start();
```

`start()` returns immediately; call it after the user's consent answer is
known. The controller does not show an ad after a background shorter than
`minimumBackgroundDuration` (a permission dialog, a share sheet), after a click
on any ad, or on top of another full-screen ad.

### Native ads

```dart
final nativeAd = NativeAd(
  adRequest: const AdRequest(adUnitId: 'demo-native-content-yandex'),
  width: 324,
  height: 432,
  template: NativeAdTemplate.media,
  style: NativeAdStyle.brandSafe,
);

// In build():
NativeAdWidget(nativeAd: nativeAd)

await nativeAd.load();
await nativeAd.destroy();
```

The native SDK binds the assets, the media view, the feedback button and the
clicks. Minimum container sizes are computed from the template and the content
padding — 324 × 412 for `compact` and 324 × 432 for `media` at the default
padding; use `minimumWidthFor` and `minimumHeightFor` when you change it. If
the loaded creative still needs more room, the ad is not shown and
`onAdFailedToLoad` reports the size it actually needs.

When Flutter recreates the platform view — scrolling far out of a list and back
— the ad is requested again for the new view, at most once per
`NativeAd.reloadInterval` (30 seconds).

### Ad events

```dart
YandexAds.events.listen((event) {
  analytics.log(event.type.name, {
    'format': event.format.name,
    'adUnitId': event.adUnitId,
  });
});
```

One stream for banners, full-screen formats and native ads: loads, failures,
impressions, clicks, dismissals and rewards. Events are delivered live and
never buffered, so subscribe before creating the first ad. `impressionData`
carries revenue figures — treat it as commercial data. The plugin sends these
events nowhere.

## How an ad is closed

The close button, its countdown and the sound control are drawn by the Yandex
Mobile Ads SDK and by the creative. `InterstitialAd` exposes three members —
`getAdInfo`, `setAdEventListener` and `show` — so neither this plugin nor the
ad unit settings can move the button, shorten the countdown or remove a forced
view.

What is a choice is the format: an app open ad is dismissed at once through its
own return control, an interstitial may hold the screen for the length of the
creative. The example app has a screen that switches between both preloaded
formats so the difference can be seen on a device. Note that an app open ad is
sold as advertising for opening or returning to the app; using it as a
mid-session interstitial is a decision for the publisher and its ad network.

## What this fork changes

* Every operation is awaitable and finishes: `load`, `show`, `cancelLoading`,
  `destroy` and initialization. Pending loads end with an error, cancellation
  and timeouts are real, and releasing resources is idempotent.
* Android reported a failed show as a successful one — the constant for
  `onAdFailedToShow` carried the wrong name. Fixed.
* A load that answers after its timeout no longer leaves a native ad and its
  channels alive.
* Banner and native ad loads can no longer hang forever waiting for a widget
  that never appears.
* Reward callbacks are delivered once per view. A client callback is not proof
  of a view: verify valuable rewards on your own server.
* `mavenLocal()` no longer outranks Google and Maven Central when resolving the
  native SDK.
* Added: `FullscreenAdPool`, `AdFrequencyPolicy`, `AppOpenAdController`,
  `NativeAd`, `ManagedBannerAdController`, `YandexAds.events`.

Full list: [CHANGELOG.md](CHANGELOG.md).

## Limits and what is not verified

* iOS is not compiled: the fork was developed on Windows. The Swift sources
  were reviewed statically and checked against the SDK 8 documentation and the
  official examples, but an Xcode build is required before trusting them.
* Android is verified by building and running the example app on a device;
  real fill, impressions and clicks on production ad units are not.
* Moving the system clock forward ages the frequency history out — the gate has
  no monotonic time source.
* A banner covered by another widget inside the same screen still counts as
  visible; dialogs and route changes are handled.
* The package still reports version 8.3.0, same as upstream. Pin it by path or
  git so a pub.dev resolution cannot silently replace it.

## License

The published package archive contains Apache 2.0, while the official
repository ships a separate Yandex Mobile Ads SDK agreement that restricts
redistribution. The two are kept side by side in [LICENSE](LICENSE) and
[LICENSE-PLUGIN-APACHE](LICENSE-PLUGIN-APACHE); distributing this fork or
publishing it as a package needs that conflict resolved first.

The native SDK stays an external dependency and is covered by the
[Yandex Mobile Ads SDK agreement](https://yandex.com/legal/mobileads_sdk_agreement/).
Upstream documentation: <https://yandex.com/dev/mobile-ads/doc/intro/about.html>

## Integration

### Mediation

##### You can also connect our libraries with all available mediations:

#### Android

`android/app/build.gradle`:

You can use common mediation dependency including all adapters (recommended):

```groovy
dependencies {
    // ...
    implementation 'com.yandex.android:mobileads-mediation:8.3.0.0'
}
```

Or you can choose adapters manually and include only their dependencies:

```groovy
dependencies {
    // ...
    implementation 'com.yandex.android:mobileads:8.3.0'
    implementation 'com.yandex.ads.mediation:mobileads-google:25.2.0.2'
    implementation 'com.yandex.ads.mediation:mobileads-inmobi:11.0.0.3'
    implementation 'com.yandex.ads.mediation:mobileads-mytarget:5.45.3.4'
    implementation 'com.yandex.ads.mediation:mobileads-unityads:4.17.0.3'
    implementation 'com.yandex.ads.mediation:mobileads-applovin:13.6.3.0'
    implementation 'com.yandex.ads.mediation:mobileads-ironsource:9.2.0.3'
    implementation 'com.yandex.ads.mediation:mobileads-chartboost:9.3.1.31'
    implementation 'com.yandex.ads.mediation:mobileads-pangle:8.0.0.5.2'
    implementation 'com.yandex.ads.mediation:mobileads-tapjoy:14.3.1.12'
    implementation 'com.yandex.ads.mediation:mobileads-vungle:7.7.0.3'
    implementation 'com.yandex.ads.mediation:mobileads-mintegral:17.0.41.3'
    implementation 'com.yandex.ads.mediation:mobileads-bigoads:5.7.0.3'
}
```

If you plan to use AdMob, you need to add your AdMob ID to the AndroidManifest.xml file
using a `<meta-data>` tag with `com.google.android.gms.ads.APPLICATION_ID`:

```xml
<manifest>
    <application>
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
    </application>
</manifest>
```

Some adapters also require adding specific maven urls:

`android/build.gradle`:

```groovy
allprojects {
    repositories {
        // ...
        // IronSource
        maven { url 'https://android-sdk.is.com/' }
        // Pangle
        maven { url 'https://artifact.bytedance.com/repository/pangle' }
        // Tapjoy
        maven { url "https://sdk.tapjoy.com/" }
        // Mintegral
        maven { url "https://dl-maven-android.mintegral.com/repository/mbridge_android_sdk_oversea" }
        // Chartboost
        maven { url "https://cboost.jfrog.io/artifactory/chartboost-ads/" }
        // AppNext
        maven { url "https://dl.appnext.com/" }
        // PetalAds
        maven { url "https://developer.huawei.com/repo/" }
    }
}
```

#### iOS

You can use common mediation dependency including all adapters (recommended):

`ios/Podfile`:

```ruby
pod 'YandexMobileAdsMediation', '~> 8.3.0'
```

Or you can choose adapters manually and include only their dependencies:

```ruby
pod 'YandexMobileAds', '~> 8.3.0'
pod 'GoogleYandexMobileAdsAdapters', '13.3.0.2'
pod 'InMobiYandexMobileAdsAdapters', '10.7.8.6'
pod 'MyTargetYandexMobileAdsAdapters', '5.36.2.3'
pod 'UnityAdsYandexMobileAdsAdapters', '4.16.6.3'
pod 'AppLovinYandexMobileAdsAdapters', '13.5.1.3'
pod 'IronSourceYandexMobileAdsAdapters', '9.3.0.3'
pod 'MintegralYandexMobileAdsAdapters', '8.0.7.3'
pod 'ChartboostYandexMobileAdsAdapters', '9.11.0.3'
pod 'BigoADSYandexMobileAdsAdapters', '5.0.6.3'
```

If you plan to use AdMob, add the GADApplicationIdentifier key with your AdMob ID
to your app's Info.plist file:

`ios/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

Networks also require adding specific SKAdNetworkIdentifiers to SKAdNetworkItems:

`ios/Info.plist`:

```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <!-- Yandex Ads -->
        <key>SKAdNetworkIdentifier</key>
        <string>zq492l623r.skadnetwork</string>
    </dict>
    <dict>
        <!-- Google (ex. AdMob) -->
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <dict>
        <!-- VK Ads (ex. myTarget) -->
        <key>SKAdNetworkIdentifier</key>
        <string>n9x2a789qt.skadnetwork</string>
    </dict>
    <dict>
        <!-- VK Ads (ex. myTarget) -->
        <key>SKAdNetworkIdentifier</key>
        <string>r26jy69rpl.skadnetwork</string>
    </dict>
    <dict>
        <!-- Start.io -->
        <key>SKAdNetworkIdentifier</key>
        <string>5l3tpt7t6e.skadnetwork</string>
    </dict>
    <dict>
        <!-- Vungle -->
        <key>SKAdNetworkIdentifier</key>
        <string>gta9lk7p23.skadnetwork</string>
    </dict>
    <dict>
        <!-- UnityAds -->
        <key>SKAdNetworkIdentifier</key>
        <string>4dzt52r2t5.skadnetwork</string>
    </dict>
    <dict>
        <!-- IronSource -->
        <key>SKAdNetworkIdentifier</key>
        <string>su67r6k2v3.skadnetwork</string>
    </dict>
    <dict>
        <!-- Applovin -->
        <key>SKAdNetworkIdentifier</key>
        <string>ludvb6z3bs.skadnetwork</string>
    </dict>
    <dict>
        <!-- Mintegral -->
        <key>SKAdNetworkIdentifier</key>
        <string>kbd757ywx3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>633vhxswh4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>tmhh9296z4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>vcra2ehyfk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>zh3b7bxvad.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>xmn954pzmp.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>79w64w269u.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>488r3q3dtq.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>d7g9azk84q.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>nzq8sh4pbs.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>866k9ut3g3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2q884k2j68.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x8jxxk4ff5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gfat3222tu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>pd25vrrwzn.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>lr83yxwka7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cp8zw746q7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>pwdxu55a5a.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c6k4g5qg8m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>s39g8k73mm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>wg4vff78zm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>g28c52eehv.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>523jb4fst2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>294l99pt4k.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3qy4746246.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>a8cz6cu7e5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ggvn48r87g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>y755zyxw56.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>qlbq5gtkt8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mls7yz5dvl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>67369282zy.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>899vrgt9g8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mj797d8u6f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3sh42y64q3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f38h382jlk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>24t9a8vw3c.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mp6xlyr22a.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x44k69ngh6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>88k8774x49.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hs6bdukanm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t3b3f7n3x8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>prcb7njmu6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c7g47wypnu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>52fl2v3hgk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9vvzujtq5s.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>m8dbw4sv7c.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9g2aggbj52.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>m5mvw97r93.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>z5b3gh5ugf.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dd3a75yxkv.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9nlqeag3gk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cj5566h2ga.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>h5jmj969g5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dr774724x4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t7ky8fmwkd.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>fz2k2k5tej.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>u679fj5vs4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cs644xg564.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9b89h5y424.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>w28pnjg2k4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2rq3zucswp.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>a7xqa6mtl2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>g2y4y55b64.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>vc83br9sjg.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>eqhxz8m8av.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7k3cvf297u.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>w9q455wk68.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>nu4557a4je.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v4nxqhlyqp.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>wzmmz9fp6w.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7fmhfwg9en.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>yclnxrl5pm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7tnzynbdc7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>l6nv3x923s.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>h8vml93bkz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>uzqba5354d.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8qiegk9qfv.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v79kvwwj4g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>xx9sdjej2w.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>au67k4efj4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t38b2kh725.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7ug5zh24hu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>rx5hdcabgc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5lm9lj6jb7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>qqp299437r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>zmvfpc5aq8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9rd848q2bz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>79pbpufp6p.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dmv22haz9p.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>y5ghdn5j9k.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n6fk4nfna4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7rz58n8ntl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v9wttpbfk9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n38lu8286q.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>feyaarzu9v.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7fbxrn65az.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>47vhws6wlr.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ejvt5qm6ak.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>b55w3d8y8z.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v7896pgt74.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5ghnmfs3dh.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>275upjj5gd.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>627r9wr2y5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>sczv5946wb.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8w3np9l82g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hb56zgv37p.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9t245vhmpl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>nrt9jy4kw9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7953jerfzd.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dn942472g5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6v7lgmsu45.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cad8qz2s3j.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>eh6m2bh4zr.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>jb7bn6koa5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>fkak3gfpt6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>a2p9lx4jpn.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>97r2b46745.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>22mmun2rn5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>238da6jt44.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>44jx6755aq.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>b9bk5wbcq9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>k674qkevps.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>tl55sbb4fm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>24zw6aqk47.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4468km3ulz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2tdux39lx8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2u9pt9hc89.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8s468mfl3y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3cgn6rq224.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>glqzh8vgby.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>av6w8kgt66.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>klf5c3l5u5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>nfqy3847ph.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dticjx1a9i.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ppxm28t8ap.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9wsyqb3ku7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>74b6s63p6l.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>xy9t38ct57.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>424m5254lk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>qu637u8glc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f73kdq92p3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>44n7hlldy6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>kbmxgpxpgc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ecpz2srf59.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x5854y7y24.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f7s53z58qe.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x8uqf25wch.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>uw77j35x4d.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6964rsfnh4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gvmwg8q7h5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6yxyv74ff7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>84993kbrcf.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>54nzkqm89y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>pwa73g5rt2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mlmmfzh3r3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9yg77x724h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n66cz3y3bx.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>578prtvx9j.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>bvpn9ufa9b.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6qx585k4p6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mtkv5xtk9e.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>l93v5h6a4m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>rvh3l7un93.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gta9lk7p23.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5tjdwbrq8w.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>r45fhb6rf7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>32z4fx6l9h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>e5fvkxwrpn.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8c4e2ghe7u.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>axh5283zss.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3rd42ekr43.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5mv394q32t.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3qcr597p9d.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v72qych5uu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ydx93a7ass.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4pfyvq9l8r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5a6flpkh64.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4fzdc2evr5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4w7y6s5ca2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>252b5q8x7y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2fnua5tdw4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3l6bd9hu43.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4mn522wn87.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6g9af3uyq4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6p4ks3rnbw.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6xzpu9s2p8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>737z793b9f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>89z7zv988g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8m87ys6875.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8r8llnkz5a.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>bxvub5ada5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c3frkrj4fj.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cg4yq2srnc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dbu4b84rxf.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dkc879ngq3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dzg6xy7pwj.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gta8lk7p23.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hdw39hrw9y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hjevpa356n.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>krvm3zuq6h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ln5gz23vtd.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>m297p6643m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>p78axxw29g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>pu4na253f3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>s69wq72ugq.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t6d3zquu66.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>vutu7akeur.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x2jnk7ly8j.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x5l83yy675.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>y45688jllp.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>yrqqpx2mcb.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>z4gj7hsk7h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>33r6p7g8nc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>g69uk9uh2b.skadnetwork</string>
    </dict>
</array>
```

[DOCUMENTATION]: https://yandex.com/dev/mobile-ads/doc/intro/about.html

[LICENSE]: https://yandex.com/legal/mobileads_sdk_agreement/
