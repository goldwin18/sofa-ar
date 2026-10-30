import 'package:flutter/material.dart';

import '../../../core/widgets/sofa_image.dart';
import '../../../data/models/sofa.dart';

/// Row of small sofa thumbnails so the client can swap sofas without leaving the camera.
class SofaPickerStrip extends StatelessWidget {
  const SofaPickerStrip({
    super.key,
    required this.sofas,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Sofa> sofas;
  final String selectedId;
  final ValueChanged<Sofa> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sofas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sofa = sofas[i];
          final selected = sofa.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(sofa),
            child: Container(
              width: 96,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(selected ? 0.95 : 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: SofaImage(sofa: sofa),
            ),
          );
        },
      ),
    );
  }
}
