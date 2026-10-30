import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/sofa.dart';

/// Shows a sofa picture, whether it ships with the app (asset) or was added by the user (file).
class SofaImage extends StatelessWidget {
  const SofaImage({super.key, required this.sofa, this.fit = BoxFit.contain});

  final Sofa sofa;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return sofa.isAsset
        ? Image.asset(sofa.imagePath, fit: fit)
        : Image.file(File(sofa.imagePath), fit: fit);
  }
}
