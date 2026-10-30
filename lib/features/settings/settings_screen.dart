import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/snack.dart';
import '../../core/widgets/app_button.dart';
import '../../services/ar_launcher.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _keyController =
        TextEditingController(text: context.read<SettingsService>().meshyApiKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<SettingsService>().saveMeshyKey(_keyController.text);
    if (mounted) showSnack(context, 'Saved.');
  }

  Future<void> _testAr() async {
    try {
      await ArLauncher.openViewer(ArLauncher.testModelUrl, title: 'AR test', resizable: true);
    } on ArException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('AI 3D conversion', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'To turn a sofa photo into a full 3D model, the app uses the Meshy service. '
            'Create an API key at meshy.ai and paste it here. Without a key you can still '
            'use the offline "Quick 3D cut-out".',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            obscureText: true,
            autocorrect: false,
            decoration: AppTheme.inputDecoration('Meshy API key'),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Save', icon: Icons.check, onPressed: _save),
          const SizedBox(height: 32),
          Text('Troubleshooting', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Opens Google\'s AR viewer with a standard sample model (an astronaut). '
            'If it works, AR is fine on this phone. If it also closes straight away, '
            'update "Google Play Services for AR" and the Google app in the Play Store.',
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Test AR on this phone',
            icon: Icons.view_in_ar,
            outlined: true,
            onPressed: _testAr,
          ),
          const SizedBox(height: 24),
          const Text(
            'Note: the key is stored on this phone. For a public release, call Meshy from '
            'your own server instead so the key is never inside the app.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
