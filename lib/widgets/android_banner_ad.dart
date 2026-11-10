import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A single adaptive banner shared by the app's main tabs.
///
/// Debug/profile builds use Google's Android test unit; only release builds
/// request ads from HuatLui's production banner unit. iOS remains disabled
/// until a separate iOS AdMob app and banner are configured.
class AndroidBannerAd extends StatefulWidget {
  const AndroidBannerAd({super.key});

  @override
  State<AndroidBannerAd> createState() => _AndroidBannerAdState();
}

class _AndroidBannerAdState extends State<AndroidBannerAd> {
  static const _productionId = 'ca-app-pub-6586968137131686/5678691212';
  static const _testId = 'ca-app-pub-3940256099942544/9214589741';

  BannerAd? _banner;
  bool _loaded = false;
  int? _requestedWidth;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_android) return;

    final width = MediaQuery.sizeOf(context).width.floor();
    if (width <= 0 || width == _requestedWidth) return;
    _requestedWidth = width;
    _load(width);
  }

  Future<void> _load(int width) async {
    final previous = _banner;
    _banner = null;
    _loaded = false;
    previous?.dispose();

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || _requestedWidth != width || size == null) return;

    final ad = BannerAd(
      adUnitId: kReleaseMode ? _productionId : _testId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || _banner != ad) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || _banner != ad) return;
          setState(() {
            _banner = null;
            _loaded = false;
          });
        },
      ),
    );
    if (!mounted || _requestedWidth != width) {
      ad.dispose();
      return;
    }
    _banner = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_android || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }
    final size = _banner!.size;
    return Center(
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: AdWidget(ad: _banner!),
      ),
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }
}
