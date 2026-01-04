import 'dart:io';

class AdConfig {
  static String bannerUnitId() {
    if (Platform.isAndroid) {
      // AdMob test banner unit ID
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      // AdMob test banner unit ID
      return 'ca-app-pub-3940256099942544/2934735716';
    }

    // Not supported (e.g., web/desktop).
    return '';
  }
}
