import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // AdMob Banner Ad Unit ID - Use test ID for development
  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID for development
  // Production ID: 'ca-app-pub-3268409402826303/9509708177'

  @override
  void initState() {
    super.initState();
    // Delay ad loading to prevent WebView crashes
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadAd();
      }
    });
  }

  void _loadAd() {
    try {
      _bannerAd = BannerAd(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner ad failed to load: $err');
          debugPrint('Error code: ${err.code}');
          debugPrint('Error message: ${err.message}');
          ad.dispose();
          setState(() {
            _isLoaded = false;
          });
        },
        onAdOpened: (Ad ad) => debugPrint('Banner ad opened.'),
        onAdClosed: (Ad ad) => debugPrint('Banner ad closed.'),
        onAdImpression: (Ad ad) => debugPrint('Banner ad impression.'),
      ),
    );
    
    _bannerAd?.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      setState(() {
        _isLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // Show placeholder while loading or if failed to load
      return Container(
        width: 320,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Loading Ad...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// Large Banner Ad Widget (for different placements)
class LargeBannerAdWidget extends StatefulWidget {
  const LargeBannerAdWidget({Key? key}) : super(key: key);

  @override
  State<LargeBannerAdWidget> createState() => _LargeBannerAdWidgetState();
}

class _LargeBannerAdWidgetState extends State<LargeBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // AdMob Banner Ad Unit ID - Use test ID for development
  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID for development
  // Production ID: 'ca-app-pub-3268409402826303/9509708177'

  @override
  void initState() {
    super.initState();
    // Delay ad loading to prevent WebView crashes
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _loadAd();
      }
    });
  }

  void _loadAd() {
    try {
      _bannerAd = BannerAd(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        size: AdSize.largeBanner, // 320x100
        listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Large banner ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Large banner ad failed to load: $err');
          debugPrint('Error code: ${err.code}');
          debugPrint('Error message: ${err.message}');
          ad.dispose();
          setState(() {
            _isLoaded = false;
          });
        },
        onAdOpened: (Ad ad) => debugPrint('Large banner ad opened.'),
        onAdClosed: (Ad ad) => debugPrint('Large banner ad closed.'),
        onAdImpression: (Ad ad) => debugPrint('Large banner ad impression.'),
      ),
    );
    
    _bannerAd?.load();
    } catch (e) {
      debugPrint('Error loading large banner ad: $e');
      setState(() {
        _isLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // Show placeholder while loading or if failed to load
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        width: 320,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Loading Large Ad...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}