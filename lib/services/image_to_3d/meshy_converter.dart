import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_store.dart';
import '../../core/widgets/progress_dialog.dart';
import '../../data/models/sofa.dart';
import '../glb_scaler.dart';
import 'image_to_3d_service.dart';

/// AI conversion through the Meshy image-to-3D API (needs internet and an API key).
/// Produces a full textured 3D model. Check https://docs.meshy.ai if the API changes;
/// everything Meshy-specific is in this one file.
class MeshyConverter implements ImageTo3dService {
  MeshyConverter({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _endpoint = 'https://api.meshy.ai/openapi/v1/image-to-3d';
  static const _pollEvery = Duration(seconds: 5);
  static const _giveUpAfter = Duration(minutes: 10);

  @override
  String get title => 'AI 3D model (Meshy)';

  @override
  String get subtitle =>
      'Full 3D sofa from one photo. Needs internet + an API key (Settings). Takes 1–3 min.';

  @override
  Future<String> convert({required Sofa sofa, ProgressReporter? onProgress}) async {
    if (apiKey.trim().isEmpty) {
      throw ConversionException('Add your Meshy API key in Settings first.');
    }
    final headers = {
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
    };

    onProgress?.call(null, 'Sending the photo…');
    final imageBytes = await File(sofa.imagePath).readAsBytes();
    final taskId = await _createTask(headers, imageBytes);

    final modelUrl = await _waitForResult(headers, taskId, onProgress);

    onProgress?.call(null, 'Downloading the 3D model…');
    final download = await _client.get(Uri.parse(modelUrl));
    if (download.statusCode != 200) {
      throw ConversionException('Could not download the model (${download.statusCode}).');
    }

    // AI models come in arbitrary units, so resize to the real sofa width.
    final width = sofa.widthMeters ?? AppConstants.defaultSofaWidthMeters;
    final sized = GlbScaler.fitToWidth(download.bodyBytes, width);
    return FileStore.saveBytes('${sofa.id}_${DateTime.now().millisecondsSinceEpoch}.glb', sized);
  }

  Future<String> _createTask(Map<String, String> headers, List<int> imageBytes) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: headers,
      body: jsonEncode({
        'image_url': 'data:image/png;base64,${base64Encode(imageBytes)}',
        'enable_pbr': true,
        'should_remesh': true,
        'should_texture': true,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw ConversionException(
          'Meshy refused the request (${response.statusCode}). Check your API key and credits.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final id = body['result'] as String?;
    if (id == null) throw ConversionException('Meshy did not return a task id.');
    return id;
  }

  Future<String> _waitForResult(
    Map<String, String> headers,
    String taskId,
    ProgressReporter? onProgress,
  ) async {
    final deadline = DateTime.now().add(_giveUpAfter);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollEvery);

      final response = await _client.get(Uri.parse('$_endpoint/$taskId'), headers: headers);
      if (response.statusCode != 200) {
        throw ConversionException('Could not check progress (${response.statusCode}).');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? '';
      final percent = ((data['progress'] as num?) ?? 0).toDouble();

      if (status == 'SUCCEEDED') {
        final urls = data['model_urls'] as Map<String, dynamic>?;
        final glb = urls?['glb'] as String?;
        if (glb == null) throw ConversionException('Meshy finished but gave no .glb file.');
        return glb;
      }
      if (status == 'FAILED' || status == 'CANCELED') {
        final error = (data['task_error'] as Map<String, dynamic>?)?['message'];
        throw ConversionException('Conversion failed${error != null ? ': $error' : '.'}');
      }
      onProgress?.call(percent / 100, 'AI is building your sofa… ${percent.round()}%');
    }
    throw ConversionException('Conversion took too long. Please try again.');
  }
}
