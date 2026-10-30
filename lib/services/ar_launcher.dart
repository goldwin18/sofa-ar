import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../data/models/sofa.dart';

class ArException implements Exception {
  ArException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Opens Google's AR viewer (Scene Viewer / ARCore) so the sofa can be placed on the floor.
///
/// Scene Viewer only loads models from a public https link, so the model has to be
/// hosted online. The sample sofas are served from the GitHub repo through jsDelivr
/// (see [AppConstants.hostedModelsBaseUrl]).
class ArLauncher {
  ArLauncher._();

  static const _googleAppPackage = 'com.google.android.googlequicksearchbox';

  /// The public link for a sofa's model, or null if it is only stored on this phone.
  static Uri? hostedModelUrl(Sofa sofa) {
    final path = sofa.modelPath;
    if (path == null || !sofa.isAsset) return null;
    final fileName = path.split('/').last;
    return Uri.parse('${AppConstants.hostedModelsBaseUrl}/$fileName');
  }

  static Future<void> launch(Sofa sofa) async {
    final modelUrl = hostedModelUrl(sofa);
    if (modelUrl == null) {
      throw ArException(
        'AR needs the 3D model to be online, and models you create on the phone are not '
        'uploaded yet. Use the 3D viewer or the camera overlay for this sofa.',
      );
    }

    await _checkModelIsReachable(modelUrl);

    final viewerUri = Uri.https('arvr.google.com', '/scene-viewer/1.0', {
      'file': modelUrl.toString(),
      'mode': 'ar_preferred',
      'title': sofa.name,
      'resizable': 'false', // keep true-to-size
    });

    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: viewerUri.toString(),
      package: _googleAppPackage,
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    try {
      await intent.launch();
    } on PlatformException {
      throw ArException(
        'Could not open the AR viewer. Make sure the Google app and '
        '"Google Play Services for AR" are installed and up to date, and that '
        'this phone supports ARCore.',
      );
    }
  }

  /// Google's viewer closes silently when it cannot download the model, so we test the link
  /// first and show the real reason instead.
  static Future<void> _checkModelIsReachable(Uri url) async {
    try {
      final response = await http.head(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw ArException(
          'The 3D model could not be downloaded (error ${response.statusCode}).\n'
          'Make sure the GitHub repo is public and the file is pushed:\n$url',
        );
      }
    } on TimeoutException {
      throw ArException('The model download timed out. Check your internet connection.');
    } on SocketException {
      throw ArException('No internet connection. AR needs to download the 3D model.');
    }
  }
}
