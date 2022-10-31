import 'dart:async';

import 'package:ds_ads/src/ds_ads_manager.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ds_ads_interstitial_state.dart';

class DSAdsInterstitialLoadedEvent extends DSAdsEvent {
  final Ad ad;

  const DSAdsInterstitialLoadedEvent._({
    required this.ad,
  });
}

class DSAdsInterstitialCubit extends Cubit<DSAdsInterstitialState> {
  final String adUnitId;
  final int loadRetryMaxCount;
  final Duration loadRetryDelay;

  var _isDisposed = false;

  DSAdsInterstitialCubit({
    required this.adUnitId,
    this.loadRetryMaxCount = 3,
    this.loadRetryDelay = const Duration(seconds: 1),
  })
      : super(DSAdsInterstitialState(
    ad: null,
    adState: AdState.none,
    loadedTime: DateTime(0),
    lastShowedTime: DateTime(0),
    loadRetryCount: 0,
  ));

  void dispose() {
    _isDisposed = true;
    cancelCurrentAd();
  }

  void _report(String eventName, {String? customAdId}) {
    DSAdsManager.instance.onReportEvent?.call(eventName, {
      'adUnitId': customAdId ?? adUnitId,
    });
  }

  /// Fetch interstital ad
  void fetchAd({
    Duration? minWait,
    Function()? then,
  }) {
    if (DSAdsManager.instance.appState.isPremium || _isDisposed) {
      then?.call();
      return;
    }

    if ([AdState.loading, AdState.loaded].contains(state.adState)) {
      then?.call();
      return;
    }
    if (DateTime.now().difference(state.loadedTime) < (minWait ?? DSAdsManager.instance.defaultFetchAdWait)) {
      then?.call();
      return;
    }

    _report('ads_interstitial: start loading');
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) async {
          try {
            _report('ads_interstitial: loaded', customAdId: ad.adUnitId);
            DSAdsManager.instance.emitEvent(DSAdsInterstitialLoadedEvent._(ad: ad));
            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
              DSAdsManager.instance.onPaidEvent(ad, valueMicros, precision, currencyCode, 'interstitialAd');
            };

            await state.ad?.dispose();
            emit(state.copyWith(
              ad: ad,
              adState: AdState.loaded,
              loadedTime: DateTime.now(),
              loadRetryCount: 0,
            ));
          } catch (e, stack) {
            Fimber.e('$e', stacktrace: stack);
          }
          then?.call();
        },
        onAdFailedToLoad: (err) async {
          try {
            await state.ad?.dispose();
            emit(state.copyWith(
              ad: null,
              adState: AdState.none,
              loadRetryCount: state.loadRetryCount + 1,
            ));
            if (state.loadRetryCount < loadRetryMaxCount) {
              await Future.delayed(loadRetryDelay);
              if (state.adState == AdState.none && !_isDisposed) {
                _report('ads_interstitial: retry loading');
                fetchAd(minWait: minWait, then: then);
              }
            } else {
              _report('ads_interstitial: failed to load');
              Fimber.w('$err', stacktrace: StackTrace.current);
              emit(state.copyWith(
                ad: null,
                loadedTime: DateTime.now(),
              ));
              then?.call();
            }
          } catch (e, stack) {
            Fimber.e('$e', stacktrace: stack);
          }
        },
      ),
    );

    emit(state.copyWith(
      adState: AdState.loading,
    ));
  }

  void cancelCurrentAd() {
    _report('ads_interstitial: cancel current ad');
    state.ad?.dispose();
    emit(state.copyWith(
      ad: null,
      adState: AdState.none,
    ));
  }

  /// Show interstitial ad. Can wait fetching if [dismissAdAfter] more than zero.
  /// [allowFetchNext] allows start fetching after show interstitial ad.
  Future<void> showAd({
    final Duration dismissAdAfter = const Duration(),
    final allowFetchNext = true,
    Function()? onAdShow,
    Function()? then,
  }) async {
    if (DSAdsManager.instance.appState.isPremium || _isDisposed) {
      then?.call();
      return;
    }

    if (!DSAdsManager.instance.appState.isInForeground) {
      then?.call();
      fetchAd();
      // https://support.google.com/admob/answer/6201362#zippy=%2Cdisallowed-example-user-launches-app
      return;
    }

    if ([AdState.preShowing, AdState.showing].contains(state.adState)) {
      Fimber.e('showAd recall (state: $state)', stacktrace: StackTrace.current);
      _report('ads_interstitial: showing canceled by error');
      then?.call();
      return;
    }

    if ([AdState.none, AdState.loading].contains(state.adState)) {
      if (dismissAdAfter.inSeconds <= 0) {
        _report('ads_interstitial: showing canceled: not ready immediately (dismiss ad after ${dismissAdAfter.inSeconds}s)');
        if (allowFetchNext) {
          fetchAd();
        }
        then?.call();
      } else {
        var processed = false;
        Timer(dismissAdAfter, () {
          if (processed) return;
          processed = true;
          _report('ads_interstitial: showing canceled: not ready after ${dismissAdAfter.inSeconds}s');
          then?.call();
        });
        fetchAd(
          then: () async {
            while (state.adState == AdState.loading) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
            if (processed) return;
            processed = true;
            if (_isDisposed) {
              _report('ads_interstitial: showing canceled: manager disposed');
              then?.call();
              return;
            }
            if (state.adState == AdState.none) {
              // Failed to fetch ad
              then?.call();
              return;
            }
            await showAd(onAdShow: onAdShow, then: then);
          },
        );
      }
      return;
    }

    final ad = state.ad;
    if (ad == null) {
      Fimber.e('ad $adUnitId is null but state: ${state.adState}', stacktrace: StackTrace.current);
      _report('ads_interstitial: showing canceled by error');
      then?.call();
      cancelCurrentAd();
      if (allowFetchNext) {
        fetchAd();
      }
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          try {
            _report('ads_interstitial: showed full screen content');
            emit(state.copyWith(
              adState: AdState.showing,
            ));
            onAdShow?.call();
          } catch (e, stack) {
            Fimber.e('$e', stacktrace: stack);
          }
          then?.call();
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          try {
            _report('ads_interstitial: full screen content dismissed');
            ad.dispose();
            emit(state.copyWith(
              ad: null,
              adState: AdState.none,
              lastShowedTime: DateTime.now(),
            ));
            if (allowFetchNext) {
              fetchAd(minWait: const Duration());
            }
            // если перенести then?.call() сюда, возникает краткий показ предыдущего экрана при закрытии интерстишла
          } catch (e, stack) {
            Fimber.e('$e', stacktrace: stack);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          try {
            _report('ads_interstitial: showing canceled by error');
            Fimber.e('$error', stacktrace: StackTrace.current);
            ad.dispose();
            emit(state.copyWith(
              ad: null,
              adState: AdState.none,
              lastShowedTime: DateTime.now(),
            ));
          } catch (e, stack) {
            Fimber.e('$e', stacktrace: stack);
          }
          then?.call();
          if (allowFetchNext) {
            fetchAd(minWait: const Duration());
          }
        },
        onAdClicked: (ad) {
          try {
            _report('ads_interstitial: ad clicked');
          } catch (e, stack) {
            Fimber.e('$e', stacktrace: stack);
          }
        }
    );
    emit(state.copyWith(
      adState: AdState.preShowing,
      lastShowedTime: DateTime.now(),
    ));

    if (_isDisposed) {
      _report('ads_interstitial: showing canceled: manager disposed');
      then?.call();
      return;
    }

    _report('ads_interstitial: start showing');
    await ad.show();
  }

  void updateLastShowedTime() {
    emit(state.copyWith(
      lastShowedTime: DateTime.now(),
    ));
  }
}
