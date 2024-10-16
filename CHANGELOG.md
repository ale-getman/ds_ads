## 1.0.3
- pub.dev score minor improvements

## 1.0.2
- fix external references to pro.altush.ads.ds_ads package

## 1.0.1
- fix Flutter 3.24 release build

## 1.0.0
- update dependencies
- dart format applied

## 0.8.5
- prepare to prohibit direct links to google_mobile_ads and applovin_max from projects
- add "I" property as the alias of "instance"

## 0.8.4
- pinned applovin_max to 3.10.1

## 0.8.3
- add DSConsentStatus type to prevent google_mobile_ads import

## 0.8.2
- downgrade AppLovin max to the last stable version - 3.10.1. 4.0.0 is bugly too

## 0.8.1
- changed 'Advertising in' to 'Ad in'
- updated dependencies
- mark DSAdsBanner.adaptive property as not used

## 0.8.0
- experimental support of AppLovin Flutter natives
- experimental add consent support for iOS
- remove native2 mixin (was in experimental status since version 0.4)
- copy AppOpen block implementation from Interstitial to Rewarded ads (fix app open after rewarded ad issue)
- add optional andLockFor parameter to unlockUntilAppResume
- fix isAdAvailable

## 0.7.0
- add DSAdsManager.splashAppOpen
- fix call DSAdSource.interstitial as source instead of DSAdSource.interstitial2 and DSAdSource.interstitialSplash
- fix recreating splashInterstitial on isAdShowing call
- add duration to event ads_manager: AppLovin initialized
- ads dependencies updated

## 0.6.1
- add optional counter before interstitial

## 0.6.0
- update google_mobile_ads to 5.1.0 
- banner optimizations
- add waitForInit method
- applovin_max updated

## 0.5.2
- add AppLovin 3.6.0 support
- remove appLovinSDKConfiguration property

## 0.5.1
- added consent form support
- google_mobile_ads and applovin_max updated
- ds_common minimum version updated

## 0.5.0
- add different ids support for interstitial ads
- update applovin_max dependency
- fix unclickable native ad after reload
- fix banner bug for premium mode

BREAKING CHANGE
- DSAdsInterstitialType replaced to part of DSAdSource

## 0.4.0
- add banners support
- аdd experimental native2 mixin
- update dependencies: Flutter to 3.10, etc
- fix tryNextMediation availability checks
- remove bloc state management
- fixed app open showing after click on interstitial (rare case)
- optimize AppLovin initialization

## 0.3.2
- fix AppLovin native ads for Yandex adapter (banner and size for video)
- fix app open showing after interstitial
- add adapter attribute in events report

## 0.3.1
- dependencies updated

## 0.3.0
- app open support added
- native add reload allowed
- dynamic mediation selection improved
- added google_mobile_ads v3 and dart v3 support

BREAKING CHANGES
- Flutter prior 3.0 is unsupported
- Yandex mediation removed
- parameters of many methods changed

## 0.2.0
- added beforeAdShow callback to DSAdsInterstitialCubit.showAd
- added events base classes: DSAdsInterstitialEvent and DSAdsNativeEvent
- allowed to dynamically bloc ads loading and showing by DSAdsManager.isAdAllowedCallback
- allowed to use google_mobile_ads 1.3.0 (for experimental purposes)

BREAKING CHANGES
- location attribute is strictly typified
- defaultFetchAdWait renamed to defaultFetchAdDelay and now it's deprecated
- AdState renamed to DSAdState

## 0.1.2
- fixed destroying the displayed interstitial ad
- build fixed

## 0.1.1
- extended support of separated interstitial ad (eg. splash): add parameter allowFetchNext to showAd
- fixed disposeClass exception

## 0.1.0
- dark theme support
- new style NativeAdBannerStyle.style2 added
- native ad preload

BREAKING CHANGES 
- add DS prefix to all classes

## 0.0.3
- fixed interstitial ads showing bugs

## 0.0.2
- fixed AdMob SDK error “Too many recently failed requests”
- debug code removed
- minor improvements

## 0.0.1
- init
