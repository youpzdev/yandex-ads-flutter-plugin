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

final class GetCalculatedBannerAdSizeCommandProvider: CommandProvider {
    
    private let bannerAdSizeFactory: BannerAdSizeFactory
    
    init(bannerAdSizeFactory: BannerAdSizeFactory) {
        self.bannerAdSizeFactory = bannerAdSizeFactory
    }
    
    var commands: [Command] {
        [
            .command(.bannerAdSize(.bannerAdSize), getCalculatedBannerAdSize)
        ]
    }
    
    let name = "bannerAdSize"
    
    private func getCalculatedBannerAdSize(args: Any?, result: MethodCallResult) {
        guard let params = args as? [String: Any?] else {
            return result.error(.argsIsNotMap)
        }
        
        let bannerAdSize = bannerAdSizeFactory.createFromCommandParams(params: params)
        let size = bannerAdSize.size;
        let intWidth = Int(size.width)
        let intHeight = Int(size.height)
        
        let calculatedSize = [
            "width": intWidth,
            "height": intHeight,
            "widthInPixels": intWidth,
            "heightInPixels": intHeight
        ]
        
        result.success(calculatedSize)
    }
}
