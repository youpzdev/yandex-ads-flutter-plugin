/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 *
 * Modified in this local fork.
 */

import Flutter

@MainActor
final class NativeAdViewFactory: NSObject, FlutterPlatformViewFactory {

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let parameters = Self.values(from: args)
        let id = Self.intValue(parameters["id"]) ?? -1
        let size = NativeAdDisplaySize(
            width: Self.intValue(parameters["width"]) ?? Int(frame.width),
            height: Self.intValue(parameters["height"]) ?? Int(frame.height)
        )
        let template = NativeAdTemplate(rawValue: parameters["template"] as? String) ?? .compact
        let style = NativeAdStyle(values: Self.values(from: parameters["style"]))
        let channelName = "\(YandexMobileAdsPlugin.channelName).nativeAd.\(id)"
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        let eventChannel = FlutterEventChannel(name: "\(channelName).events", binaryMessenger: messenger)
        let nativeAdView = FlutterNativeAdView(
            displaySize: size,
            template: template,
            style: style,
            methodChannel: methodChannel,
            eventChannel: eventChannel
        )

        methodChannel.setMethodCallHandler { [weak nativeAdView] call, result in
            Task { @MainActor in
                guard let nativeAdView else {
                    result(FlutterError(
                        code: "disposed",
                        message: "native ad view is unavailable",
                        details: nil
                    ))
                    return
                }
                nativeAdView.handle(call: call, result: result)
            }
        }

        return nativeAdView
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    private static func intValue(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite,
              number.doubleValue.rounded(.towardZero) == number.doubleValue,
              number.doubleValue >= Double(Int.min),
              number.doubleValue <= Double(Int.max) else {
            return nil
        }
        return number.intValue
    }

    private static func values(from arguments: Any?) -> [String: Any] {
        if let values = arguments as? [String: Any] {
            return values
        }
        guard let values = arguments as? [String: Any?] else { return [:] }
        return values.reduce(into: [:]) { result, entry in
            if let value = entry.value {
                result[entry.key] = value
            }
        }
    }
}
