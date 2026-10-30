import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_navigator.dart';
import '../../core/utils/file_store.dart';
import '../../core/utils/snack.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/sofa.dart';
import '../../data/repositories/sofa_repository.dart';
import '../../services/background_remover.dart';

/// Lets the user add their own sofa: pick a photo, clean the background, name it, save it.
/// Converting to 3D happens afterwards on the sofa's detail screen.
class AddSofaScreen extends StatefulWidget {
  const AddSofaScreen({super.key});

  @override
  State<AddSofaScreen> createState() => _AddSofaScreenState();
}

class _AddSofaScreenState extends State<AddSofaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _styleController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _original;
  Uint8List? _prepared;
  bool _removeBackground = true;
  bool _busy = false;
  double _widthMeters = AppConstants.defaultSofaWidthMeters;

  @override
  void dispose() {
    _nameController.dispose();
    _styleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 2000);
    if (file == null) return;
    _original = await file.readAsBytes();
    await _prepare();
  }

  Future<void> _prepare() async {
    final original = _original;
    if (original == null) return;
    setState(() => _busy = true);
    try {
      final result = await BackgroundRemover.prepare(
        original,
        removeBackground: _removeBackground,
      );
      if (mounted) setState(() => _prepared = result);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not read that picture. Try another one.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_prepared == null) {
      showSnack(context, 'Pick a sofa picture first.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<SofaRepository>();
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final imagePath = await FileStore.saveBytes('$id.png', _prepared!);

    await repo.add(Sofa(
      id: id,
      name: _nameController.text.trim(),
      style: _styleController.text.trim(),
      price: _priceController.text.trim(),
      widthMeters: _widthMeters,
      imagePath: imagePath,
      isAsset: false,
    ));

    if (!mounted) return;
    // Jump straight to the new sofa so "Convert to 3D" is one tap away.
    await AppNavigator.openDetail(context, id, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add your sofa')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPreview(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Gallery',
                  icon: Icons.photo_library_outlined,
                  outlined: true,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Camera',
                  icon: Icons.photo_camera_outlined,
                  outlined: true,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remove plain background'),
            subtitle: const Text('Works best on white or light-grey backgrounds'),
            value: _removeBackground,
            onChanged: _original == null
                ? null
                : (value) {
                    setState(() => _removeBackground = value);
                    _prepare();
                  },
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: AppTheme.inputDecoration('Sofa name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _styleController,
                  decoration: AppTheme.inputDecoration('Style (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: AppTheme.inputDecoration('Price (optional)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Real width: ${_widthMeters.toStringAsFixed(2)} m',
              style: Theme.of(context).textTheme.titleSmall),
          Slider(
            value: _widthMeters,
            min: AppConstants.minSofaWidthMeters,
            max: AppConstants.maxSofaWidthMeters,
            divisions: 50,
            label: '${_widthMeters.toStringAsFixed(2)} m',
            onChanged: (v) => setState(() => _widthMeters = v),
          ),
          const Text(
            'The 3D model is built at this size, so the sofa looks true-to-scale in the room.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Save sofa', icon: Icons.check, onPressed: _busy ? null : _save),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: _busy
          ? const Center(child: CircularProgressIndicator())
          : _prepared == null
              ? const Center(
                  child: Text('Pick a photo of the sofa\n(front view works best)',
                      textAlign: TextAlign.center))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.memory(_prepared!, fit: BoxFit.contain),
                ),
    );
  }
}
