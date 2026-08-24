/*
 * This file is a part of the Yandex Advertising Network
 *
 * Version for Flutter (C) 2023 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
 */

part of 'mobile_ads.dart';

/// Class containing errors that can occur during an ad request.
enum AdRequestErrorCode {
  // from Android
  /// Ad request failed with internal error.
  internalError,

  /// Ad request configured incorrectly.
  invalidRequest,

  /// Ad request failed with connection error.
  networkError,

  /// The ad request failed with system error.
  /// For instance a WebView can't access the database file.
  /// Don't try to load/reload ads if you've got this error.
  systemError,

  /// Ad request failed with unknown error.
  unknownError,

  // from iOS
  /// The AdUnitId was omitted when loading the ad.
  emptyAdUnitId,

  /// An invalid Application ID was specified.
  invalidUUID,

  /// The AdUnitId specified when loading the ad wasn’t found.
  noSuchAdUnitId,

  /// Unexpected server response when loading the ad.
  badServerResponse,

  /// The ad size in the request does not match the ad size specified in the Partner interface for this ad block.
  adSizeMismatch,

  /// The ad type in the request does not match the ad type specified in the Partner interface for this ad block.
  adTypeMismatch,

  /// The service is temporarily unavailable. Try sending the request again later.
  serviceTemporarilyNotAvailable,

  /// An interstitial ad can be displayed only once.
  adHasAlreadyBeenPresented,

  /// ViewController for interstitial ads is nil.
  nullPresentingViewController,

  /// Incorrect view for interstitial ads.
  incorrectFullscreenView,

  // exists in both
  /// Ad request completed successfully, but there are no ads available.
  noFill,
}
