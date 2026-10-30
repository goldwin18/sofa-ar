import 'package:flutter/material.dart';

import '../../features/add_sofa/add_sofa_screen.dart';
import '../../features/camera_overlay/camera_overlay_screen.dart';
import '../../features/detail/sofa_detail_screen.dart';
import '../../features/settings/settings_screen.dart';

/// One place for every screen change, so screens don't need to know about each other.
class AppNavigator {
  AppNavigator._();

  static Future<void> openDetail(BuildContext context, String sofaId,
      {bool replace = false}) {
    final route =
        MaterialPageRoute<void>(builder: (_) => SofaDetailScreen(sofaId: sofaId));
    return replace
        ? Navigator.of(context).pushReplacement(route)
        : Navigator.of(context).push(route);
  }

  static Future<void> openCamera(BuildContext context, String sofaId) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => CameraOverlayScreen(initialSofaId: sofaId),
    ));
  }

  static Future<void> openAddSofa(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AddSofaScreen()));
  }

  static Future<void> openSettings(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }
}
