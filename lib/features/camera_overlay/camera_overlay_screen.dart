import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/permission_helper.dart';
import '../../core/utils/snack.dart';
import '../../core/widgets/message_view.dart';
import '../../data/models/sofa.dart';
import '../../data/repositories/sofa_repository.dart';
import 'sofa_overlay_controller.dart';
import 'widgets/sofa_overlay.dart';
import 'widgets/sofa_picker_strip.dart';

/// Live camera with the sofa picture on top. Works on every phone (no ARCore needed)
/// and with any sofa photo, including ones that have no 3D model.
class CameraOverlayScreen extends StatefulWidget {
  const CameraOverlayScreen({super.key, required this.initialSofaId});

  final String initialSofaId;

  @override
  State<CameraOverlayScreen> createState() => _CameraOverlayScreenState();
}

class _CameraOverlayScreenState extends State<CameraOverlayScreen>
    with WidgetsBindingObserver {
  final _overlay = SofaOverlayController();
  final _captureKey = GlobalKey();

  CameraController? _camera;
  late String _sofaId;
  bool _permissionDenied = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sofaId = widget.initialSofaId;
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _overlay.dispose();
    super.dispose();
  }

  // Release the camera when the app goes to the background, reopen it on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
      if (mounted) setState(() => _camera = null);
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    final allowed = await PermissionHelper.ensureCamera();
    if (!mounted) return;
    if (!allowed) {
      setState(() => _permissionDenied = true);
      return;
    }

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _permissionDenied = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open the camera.\n$e');
    }
  }

  /// Saves what the client sees (camera + sofa) as a picture and opens the share sheet.
  Future<void> _shareSnapshot(Sofa sofa) async {
    try {
      final boundary =
          _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sofa_preview_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: 'How the ${sofa.name} looks in my room');
    } catch (e) {
      if (mounted) showSnack(context, 'Could not save the picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sofas = context.watch<SofaRepository>().all;
    final sofa = sofas.firstWhere((s) => s.id == _sofaId, orElse: () => sofas.first);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraArea(sofa),
          _buildTopBar(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomPanel(sofas, sofa),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea(Sofa sofa) {
    if (_permissionDenied) {
      return MessageView(
        dark: true,
        icon: Icons.no_photography_outlined,
        message: 'Camera permission is needed to show the sofa in your room.',
        actionLabel: 'Open settings',
        onAction: PermissionHelper.openSystemSettings,
      );
    }
    if (_error != null) {
      return MessageView(dark: true, icon: Icons.error_outline, message: _error!);
    }
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fill the screen with the camera picture (cropping the edges if needed).
    final size = MediaQuery.sizeOf(context);
    var fill = size.aspectRatio * camera.value.aspectRatio;
    if (fill < 1) fill = 1 / fill;

    return RepaintBoundary(
      key: _captureKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Transform.scale(scale: fill, child: Center(child: CameraPreview(camera))),
          ),
          SofaOverlay(sofa: sofa, controller: _overlay),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Drag to move  •  pinch to resize  •  twist to rotate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(List<Sofa> sofas, Sofa sofa) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SofaPickerStrip(
              sofas: sofas,
              selectedId: sofa.id,
              onSelected: (s) => setState(() {
                _sofaId = s.id;
                _overlay.reset();
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundButton(icon: Icons.flip, label: 'Flip', onTap: _overlay.flip),
                _RoundButton(icon: Icons.refresh, label: 'Reset', onTap: _overlay.reset),
                _RoundButton(
                  icon: Icons.ios_share,
                  label: 'Share',
                  onTap: () => _shareSnapshot(sofa),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
