/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Flutter

typealias CommandHandler = (Any?, MethodCallResult) -> Void

protocol CommandProvider {

    var commands: [Command] { get }
    var name: String { get }
}

extension CommandProvider {

    static var controller: UIViewController? {
        var controller = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
        while let child = controller?.presentedViewController {
            controller = child
        }
        return controller
    }

    var callHandler: FlutterMethodCallHandler {
        { call, result in
            let result = MethodCallResult(result)
            guard let command = commands.first(where: { $0.type.commandName == call.method }) else {
                return result.notImplemented()
            }
            command.block(call.arguments, result)
        }
    }
}

struct Command {

    let type: CommandType
    let block: CommandHandler

    static func command(_ type: CommandType, _ block: @escaping CommandHandler) -> Command {
        .init(type: type, block: block)
    }
}
