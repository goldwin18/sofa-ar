import 'package:flutter/material.dart';

import '../../../data/models/sofa.dart';

/// Name, price, details and the action buttons under the 3D viewer.
class SofaInfoPanel extends StatelessWidget {
  const SofaInfoPanel({super.key, required this.sofa, required this.actions});

  final Sofa sofa;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = [
      if (sofa.style.isNotEmpty) sofa.style,
      if (sofa.widthMeters != null) '${sofa.widthMeters!.toStringAsFixed(2)} m wide',
    ].join('  •  ');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(sofa.name,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (sofa.price.isNotEmpty)
                  Text(sofa.price,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(details, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 14),
            for (final action in actions) ...[
              action,
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
