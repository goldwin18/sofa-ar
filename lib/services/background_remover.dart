import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../core/constants/app_constants.dart';

class _Job {
  const _Job(this.bytes, this.removeBackground, this.tolerance);
  final Uint8List bytes;
  final bool removeBackground;
  final int tolerance;
}

/// Prepares a sofa photo: shrinks it, converts it to PNG, and (optionally) turns the
/// plain studio-style background transparent so the sofa can float over a camera view.
/// It only handles plain backgrounds (white / light grey). Busy backgrounds need a
/// proper segmentation model.
class BackgroundRemover {
  BackgroundRemover._();

  static Future<Uint8List> prepare(
    Uint8List photo, {
    required bool removeBackground,
    int tolerance = 40,
  }) {
    // Runs in another isolate so the screen doesn't freeze.
    return compute(_run, _Job(photo, removeBackground, tolerance));
  }

  static Uint8List _run(_Job job) {
    final decoded = img.decodeImage(job.bytes);
    if (decoded == null) throw const FormatException('Unreadable image');

    var image = decoded;
    final longest = math.max(image.width, image.height);
    if (longest > AppConstants.maxImageSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: AppConstants.maxImageSide)
          : img.copyResize(image, height: AppConstants.maxImageSide);
    }
    image = image.convert(numChannels: 4);

    if (job.removeBackground && image.getPixel(0, 0).a > 10) {
      _floodClearBackground(image, job.tolerance);
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Starting from the border, clears every connected pixel close to the corner colour.
  static void _floodClearBackground(img.Image image, int tolerance) {
    final w = image.width;
    final h = image.height;
    final ref = image.getPixel(0, 0);
    final refR = ref.r.toInt(), refG = ref.g.toInt(), refB = ref.b.toInt();

    bool matches(int x, int y) {
      final p = image.getPixel(x, y);
      return (p.r.toInt() - refR).abs() <= tolerance &&
          (p.g.toInt() - refG).abs() <= tolerance &&
          (p.b.toInt() - refB).abs() <= tolerance;
    }

    final seen = Uint8List(w * h);
    final queue = Queue<int>();
    void visit(int x, int y) {
      final i = y * w + x;
      if (seen[i] == 1 || !matches(x, y)) return;
      seen[i] = 1;
      queue.add(i);
    }

    for (var x = 0; x < w; x++) {
      visit(x, 0);
      visit(x, h - 1);
    }
    for (var y = 0; y < h; y++) {
      visit(0, y);
      visit(w - 1, y);
    }

    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final x = i % w;
      final y = i ~/ w;
      image.setPixelRgba(x, y, 0, 0, 0, 0);
      if (x > 0) visit(x - 1, y);
      if (x < w - 1) visit(x + 1, y);
      if (y > 0) visit(x, y - 1);
      if (y < h - 1) visit(x, y + 1);
    }
  }
}
