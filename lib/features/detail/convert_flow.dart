import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/snack.dart';
import '../../core/widgets/progress_dialog.dart';
import '../../data/models/sofa.dart';
import '../../data/repositories/sofa_repository.dart';
import '../../services/image_to_3d/converter_registry.dart';
import '../../services/image_to_3d/image_to_3d_service.dart';
import '../../services/settings_service.dart';

/// "Convert to 3D": lets the user choose a method, runs it, and attaches the result to the sofa.
Future<void> startConversion(BuildContext context, Sofa sofa) async {
  final repo = context.read<SofaRepository>();
  final converters = ConverterRegistry.build(context.read<SettingsService>());

  final chosen = await showModalBottomSheet<ImageTo3dService>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ConverterPicker(converters: converters),
  );
  if (chosen == null || !context.mounted) return;

  try {
    final modelPath = await ProgressDialog.run<String>(
      context,
      title: 'Converting to 3D',
      task: (report) => chosen.convert(sofa: sofa, onProgress: report),
    );
    await repo.attachModel(sofa.id, modelPath);
    if (context.mounted) {
      showSnack(context, '3D model ready. Tap "View in your room" to place it.');
    }
  } on ConversionException catch (e) {
    if (context.mounted) showSnack(context, e.message);
  } catch (e) {
    if (context.mounted) showSnack(context, 'Conversion failed: $e');
  }
}

class _ConverterPicker extends StatelessWidget {
  const _ConverterPicker({required this.converters});
  final List<ImageTo3dService> converters;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('How should we build the 3D model?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          for (final converter in converters)
            ListTile(
              leading: const Icon(Icons.view_in_ar_outlined),
              title: Text(converter.title),
              subtitle: Text(converter.subtitle),
              onTap: () => Navigator.pop(context, converter),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
