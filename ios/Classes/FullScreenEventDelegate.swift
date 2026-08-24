/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Flutter

class FullScreenEventDelegate: NSObject, FlutterStreamHandler {

    private var sink: FlutterEventSink?

    func respond(_ callback: FullScreenCallbackName, _ args: [String: Any?] = [:]) {
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
}

enum FullScreenCallbackName: String {
    case onAdClicked
    case onAdShown
    case onAdFailedToShow
    case onAdDismissed
    case onRewarded
    case onAdImpression
}
