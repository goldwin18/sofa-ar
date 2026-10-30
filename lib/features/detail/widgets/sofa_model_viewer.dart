import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../data/models/sofa.dart';

/// Interactive 3D viewer: drag to rotate the sofa, pinch to zoom.
/// The AR step ("View in your room") is a separate button, see ArLauncher.
class SofaModelViewer extends StatelessWidget {
  const SofaModelViewer({super.key, required this.sofa});

  final Sofa sofa;

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      // A new key reloads the viewer when the model file changes.
      key: ValueKey(sofa.viewerSource),
      src: sofa.viewerSource!,
      alt: '3D model of ${sofa.name}',
      ar: false,
      autoRotate: true,
      cameraControls: true,
      backgroundColor: const Color(0xFFF1ECE5),
    );
  }
}
