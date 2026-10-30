import 'package:flutter/material.dart';

import '../../../core/widgets/sofa_image.dart';
import '../../../data/models/sofa.dart';
import '../sofa_overlay_controller.dart';

/// The sofa picture floating on top of the camera. Handles drag / pinch / twist.
class SofaOverlay extends StatelessWidget {
  const SofaOverlay({super.key, required this.sofa, required this.controller});

  final Sofa sofa;
  final SofaOverlayController controller;

  @override
  Widget build(BuildContext context) {
    final baseWidth = MediaQuery.sizeOf(context).width * 0.7;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: controller.onScaleStart,
      onScaleUpdate: controller.onScaleUpdate,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Center(
          child: Transform.translate(
            offset: controller.offset,
            child: Transform.rotate(
              angle: controller.rotation,
              child: Transform.scale(
                scale: controller.scale,
                child: Transform.flip(
                  flipX: controller.flipped,
                  child: SizedBox(width: baseWidth, child: SofaImage(sofa: sofa)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
