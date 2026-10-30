import 'package:flutter/material.dart';

/// Remembers where the sofa picture sits on the camera view:
/// position, size, rotation and whether it is mirrored.
class SofaOverlayController extends ChangeNotifier {
  static const _minScale = 0.3;
  static const _maxScale = 4.0;

  double scale = 1;
  double rotation = 0; // radians
  Offset offset = Offset.zero;
  bool flipped = false;

  // Values captured when a gesture starts.
  double _startScale = 1;
  double _startRotation = 0;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  void onScaleStart(ScaleStartDetails details) {
    _startScale = scale;
    _startRotation = rotation;
    _startOffset = offset;
    _startFocal = details.focalPoint;
  }

  /// One finger drags, two fingers pinch (resize) and twist (rotate).
  void onScaleUpdate(ScaleUpdateDetails details) {
    scale = (_startScale * details.scale).clamp(_minScale, _maxScale);
    rotation = _startRotation + details.rotation;
    offset = _startOffset + (details.focalPoint - _startFocal);
    notifyListeners();
  }

  void flip() {
    flipped = !flipped;
    notifyListeners();
  }

  void reset() {
    scale = 1;
    rotation = 0;
    offset = Offset.zero;
    flipped = false;
    notifyListeners();
  }
}
