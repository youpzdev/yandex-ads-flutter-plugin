/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Flutter
import YandexMobileAds

class LoadDelegate: NSObject, FlutterStreamHandler {

    private var sink: FlutterEventSink?

    func respond(_ callback: LoadCallbackName, _ args: [String: Any?] = [:]) {
        var args = args
        args["name"] = callback.rawValue
        sink?(args)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    func adInfoToMap(adInfo: AdInfo?) -> [String: Any] {
        if let info = adInfo {
            return ["adUnitId" : info.adUnitID]
        } else {
            return [:]
        }
    }
}

enum LoadCallbackName: String {
    case onAdLoaded
    case onAdFailedToLoad
}
