import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../data/models/sofa.dart';

/// Interactive 3D viewer. On Android phones that support ARCore, the
/// "View in your room" button opens Google's Scene Viewer: the user points the
/// camera at the floor and the sofa is placed there in real size.
class SofaModelViewer extends StatelessWidget {
  const SofaModelViewer({super.key, required this.sofa});

  final Sofa sofa;

  static const _viewerId = 'sofaViewer';

  // The button model-viewer shows when AR is available on the device.
  static const _arButtonHtml = '''
<button slot="ar-button" style="
  position:absolute; bottom:16px; left:50%; transform:translateX(-50%);
  background:#8B5E3C; color:#fff; border:none; border-radius:24px;
  padding:12px 22px; font-size:15px; font-weight:600;
  box-shadow:0 2px 8px rgba(0,0,0,.25);">
  View in your room
</button>
''';

  // Keep the sofa at real-world size in AR (no pinch-resizing), so clients judge fit honestly.
  static const _fixedScaleJs =
      "document.getElementById('$_viewerId')?.setAttribute('ar-scale', 'fixed');";

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      // A new key reloads the viewer when the model file changes.
      key: ValueKey(sofa.viewerSource),
      id: _viewerId,
      src: sofa.viewerSource!,
      alt: '3D model of ${sofa.name}',
      ar: true,
      arModes: const ['scene-viewer', 'webxr', 'quick-look'],
      autoRotate: true,
      cameraControls: true,
      backgroundColor: const Color(0xFFF1ECE5),
      innerModelViewerHtml: _arButtonHtml,
      relatedJs: _fixedScaleJs,
    );
  }
}
