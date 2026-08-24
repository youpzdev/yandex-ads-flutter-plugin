/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Flutter

final class MethodCallResult {

    private let result: FlutterResult

    init(_ result: @escaping FlutterResult) {
        self.result = result
    }

    func error(code: String, message: String, details: Any? = nil) {
        result(FlutterError(code: code, message: message, details: details))
    }

    func error(_ reason: ErrorReason) {
        switch reason {
        case .argsIsNotMap:
            error(code: "args", message: "args must be Map<String, Object?>")
        case .argsIsNotBool:
            error(code: "args", message: "args must be bool")
        case .noViewController:
            error(code: "controller", message: "no view controller present")
        }
    }

    func notImplemented() {
        result(FlutterMethodNotImplemented)
    }

    func success(_ arg: Any? = nil) {
        result(arg)
    }
}
