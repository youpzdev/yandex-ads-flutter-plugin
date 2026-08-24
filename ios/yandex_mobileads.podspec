#
# This file is a part of the Yandex Advertising Network
#
# Version for Flutter (C) 2022 YANDEX
#
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at https://legal.yandex.com/partner_ch/
#

Pod::Spec.new do |s|
  s.name             = 'yandex_mobileads'
  s.version          = '8.3.0'
  s.summary          = 'Flutter plugin for Yandex Mobile Ads SDK'
  s.description      = <<-DESC
Flutter plugin for Yandex Mobile Ads SDK
                       DESC
  s.homepage         = 'https://ads.yandex.com/monetization/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Yandex' => 'mobads@yandex-team.ru' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'


  s.dependency 'YandexMobileAds', '~> 8.3.0'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.swift_version = '5.0'
end
