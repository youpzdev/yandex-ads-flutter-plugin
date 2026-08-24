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
import UIKit

class BaseFullscreenAdViewController: UIViewController {
    let fullScreenEvendDelegate: FullScreenEventDelegate
    
    init(fullScreenEvendDelegate: FullScreenEventDelegate = FullScreenEventDelegate()) {
        self.fullScreenEvendDelegate = fullScreenEvendDelegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder: NSCoder) {
        fullScreenEvendDelegate = FullScreenEventDelegate()
        super.init(coder: coder)
        modalPresentationStyle = .overCurrentContext
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.presentedViewController == nil else {
            return
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.presentedViewController == nil else {
            return
        }
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.presentedViewController == nil else {
            return
        }
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.presentedViewController == nil else {
            return
        }
        super.touchesCancelled(touches, with: event)
    }
    
    func adDidDismiss() {
        presentingViewController?.dismiss(animated: false)
        fullScreenEvendDelegate.respond(.onAdDismissed)
    }
    
    func adDidFailToShow(_ error: Error) {
        presentingViewController?.dismiss(animated: false)
        fullScreenEvendDelegate.respond(.onAdFailedToShow, error.toMap())
    }
}

// MARK: FlutterStreamHandler

extension BaseFullscreenAdViewController: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        fullScreenEvendDelegate.onListen(withArguments: arguments, eventSink: events)
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        fullScreenEvendDelegate.onCancel(withArguments: arguments)
    }
}
