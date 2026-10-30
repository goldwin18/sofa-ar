import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_navigator.dart';
import '../../core/utils/snack.dart';
import '../../services/ar_launcher.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/sofa_image.dart';
import '../../data/models/sofa.dart';
import '../../data/repositories/sofa_repository.dart';
import 'convert_flow.dart';
import 'widgets/sofa_info_panel.dart';
import 'widgets/sofa_model_viewer.dart';

/// Shows one sofa: a 3D viewer with "View in your room" (AR), plus the camera-overlay shortcut.
class SofaDetailScreen extends StatelessWidget {
  const SofaDetailScreen({super.key, required this.sofaId});

  final String sofaId;

  @override
  Widget build(BuildContext context) {
    final sofa = context.watch<SofaRepository>().byId(sofaId);
    if (sofa == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This sofa no longer exists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sofa.name, overflow: TextOverflow.ellipsis),
        actions: [
          if (!sofa.isAsset)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, sofa),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _Preview(sofa: sofa)),
          SofaInfoPanel(
            sofa: sofa,
            actions: [
              if (sofa.hasModel)
                AppButton(
                  label: 'View in your room (AR)',
                  icon: Icons.view_in_ar,
                  onPressed: () => _openAr(context, sofa),
                ),
              AppButton(
                label: 'Try with camera (overlay)',
                icon: Icons.photo_camera_outlined,
                outlined: true,
                onPressed: () => AppNavigator.openCamera(context, sofa.id),
              ),
              if (!sofa.isAsset)
                AppButton(
                  label: sofa.hasModel ? 'Rebuild 3D model' : 'Convert to 3D',
                  icon: Icons.view_in_ar_outlined,
                  outlined: true,
                  onPressed: () => startConversion(context, sofa),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openAr(BuildContext context, Sofa sofa) async {
    try {
      await ArLauncher.launch(sofa);
    } on ArException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Sofa sofa) async {
    final repo = context.read<SofaRepository>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this sofa?'),
        content: Text('"${sofa.name}" will be removed from this phone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    navigator.pop();
    await repo.remove(sofa.id);
  }
}

/// 3D viewer when a model exists, otherwise the plain photo with a hint.
class _Preview extends StatelessWidget {
  const _Preview({required this.sofa});
  final Sofa sofa;

  @override
  Widget build(BuildContext context) {
    if (sofa.hasModel) return SofaModelViewer(sofa: sofa);

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(padding: const EdgeInsets.all(24), child: SofaImage(sofa: sofa)),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Text(
              'No 3D model yet. Tap "Convert to 3D" to create one, or use the camera overlay.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
