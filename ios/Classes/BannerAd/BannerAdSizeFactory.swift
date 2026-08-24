/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import Foundation
import YandexMobileAds

final class BannerAdSizeFactory {

    func createFromCommandParams(params: [String: Any?]) -> BannerAdSize {

        let width: CGFloat = params[.width] ?? 0
        let height: CGFloat = params[.height] ?? 0
        let type: String = params[.type] ?? ""
        let adSize: BannerAdSize

        switch AdSizeType(rawValue: type) {
        case .inline:
            adSize = .inline(width: width, maxHeight: height)
        case .sticky:
            adSize = .sticky(containerWidth: width)
        default:
            adSize = .inline(width: 0, maxHeight: 0)
        }

        return adSize
    }
}

private enum AdSizeType: String {
    case inline, sticky
}

private enum BannerAdSizeCreationParameter: String {
    case width, height, type
}

private extension Dictionary where Key == String {
    subscript<T>(_ key: BannerAdSizeCreationParameter) -> T? {
        self[key.rawValue] as? T
    }
}
