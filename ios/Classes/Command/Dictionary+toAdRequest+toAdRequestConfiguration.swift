/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

import CoreLocation
import YandexMobileAds

extension Dictionary where Key == String {
    func toAdRequest() -> AdRequest {
        return AdRequest(
            adUnitID: self[.adUnitId] ?? "",
            targeting: .init(
                age: (self[AdRequestParameter.age.rawValue] as? String)
                    .flatMap { Int($0) }
                    .map { $0 as NSNumber },
                gender: self[.gender].map { Gender($0) },
                location: self[.location],
                contextQuery: self[.contextQuery],
                contextTags: self[.contextTags]
            ),
            adTheme: self.stringToAdTheme(adTheme: self[.preferredTheme] as String?),
            parameters: self[.parameters]
        )
    }

    private subscript<T>(_ key: AdRequestParameter) -> T? {
        self[key.rawValue] as? T
    }

    private func stringToAdTheme(adTheme: String?) -> AdTheme {
        switch adTheme {
        case "dark": .dark
        case "light": .light
        default: .unspecified
        }
    }

    private func mapToCLLocation(locationMap: [String: Double]) -> CLLocation? {
        let latitude = locationMap["latitude"]
        let longitude = locationMap["longitude"]
        let horizontalAccuracy = locationMap["accuracy"]
        if let latitude, let longitude {
            return CLLocation(coordinate: .init(latitude: latitude, longitude: longitude),
                              altitude: 0,
                              horizontalAccuracy: horizontalAccuracy ?? 0.1,
                              verticalAccuracy: 0.1,
                              timestamp: Date())
        }
        return nil
    }
}
