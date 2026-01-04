import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();

    final adUnitId = AdConfig.bannerUnitId();
    if (adUnitId.isEmpty) {
      return;
    }

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(
        nonPersonalizedAds: true,
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _loadFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _loadFailed = true;
          });
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    final colorScheme = Theme.of(context).colorScheme;
    const height = 50.0; // AdSize.banner height

    if (_isLoaded && banner != null) {
      return SizedBox(
        width: double.infinity,
        height: banner.size.height.toDouble(),
        child: Center(
          child: SizedBox(
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      );
    }

    // If ads cannot be displayed (e.g. no fill), show nothing.
    if (_loadFailed) {
      return const SizedBox.shrink();
    }

    // Reserve space while loading so the UI doesn't jump.
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
