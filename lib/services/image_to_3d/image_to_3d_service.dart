import '../../core/widgets/progress_dialog.dart';
import '../../data/models/sofa.dart';

class ConversionException implements Exception {
  ConversionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Anything that can turn a sofa picture into a .glb 3D model.
/// To add another provider, implement this and list it in [ConverterRegistry].
abstract class ImageTo3dService {
  String get title;
  String get subtitle;

  /// Returns the path of the saved .glb file.
  Future<String> convert({required Sofa sofa, ProgressReporter? onProgress});
}
