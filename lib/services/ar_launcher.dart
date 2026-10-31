import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../data/models/sofa.dart';

class ArException implements Exception {
  ArException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// "View in your room": opens a small web page in Chrome that shows the sofa in 3D and has
/// the AR button (the page is `ar.html`, hosted by GitHub Pages with the models).
///
/// Starting Google's AR viewer straight from the app failed on a real phone (it opened and
/// closed at once), while the same viewer started from Chrome worked, so we hand over to Chrome.
class ArLauncher {
  ArLauncher._();

  static const _chromePackage = 'com.android.chrome';

  /// The page for a sample sofa, or null if its model only exists on this phone
  /// (the page can only load models that are hosted online).
  static Uri? pageFor(Sofa sofa) {
    final path = sofa.modelPath;
    if (path == null || !sofa.isAsset) return null;
    final modelName = path.split('/').last.replaceAll('.glb', '');
    return Uri.parse(AppConstants.arPageUrl).replace(
      queryParameters: {'model': modelName, 'title': sofa.name},
    );
  }

  static Future<void> launch(Sofa sofa) async {
    final page = pageFor(sofa);
    if (page == null) {
      throw ArException(
        'AR needs the 3D model to be online, and models you create on the phone are not '
        'uploaded yet. Use the 3D viewer or the camera overlay for this sofa.',
      );
    }
    await _openInBrowser(page);
  }

  /// Opens the same page with a standard sample model (an astronaut) to check AR on this phone.
  static Future<void> launchTest() {
    return _openInBrowser(Uri.parse(AppConstants.arPageUrl)
        .replace(queryParameters: {'model': 'astronaut', 'title': 'AR test'}));
  }

  static Future<void> _openInBrowser(Uri url) async {
    // Chrome first (it starts Google's AR viewer), then whatever browser the phone has.
    for (final package in [_chromePackage, null]) {
      try {
        await AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: url.toString(),
          package: package,
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        return;
      } on PlatformException {
        continue; // Chrome missing: try the next option
      }
    }
    throw ArException('Could not open a web browser. Install Chrome and try again.');
  }
}
