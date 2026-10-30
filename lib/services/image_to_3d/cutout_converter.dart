import 'dart:io';

import 'package:image/image.dart' as img;

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_store.dart';
import '../../core/widgets/progress_dialog.dart';
import '../../data/models/sofa.dart';
import '../glb_builder.dart';
import 'image_to_3d_service.dart';

/// Works offline. Stands the (background-free) sofa photo up as a real-size 3D cut-out
/// that can be walked around and placed in AR. It is flat, not a full sofa shape.
class CutoutConverter implements ImageTo3dService {
  @override
  String get title => 'Quick 3D cut-out';

  @override
  String get subtitle => 'Instant, works offline. A flat standing cut-out of your photo.';

  @override
  Future<String> convert({required Sofa sofa, ProgressReporter? onProgress}) async {
    onProgress?.call(null, 'Reading the photo…');
    final bytes = await File(sofa.imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw ConversionException('Could not read the sofa photo.');
    }

    final width = sofa.widthMeters ?? AppConstants.defaultSofaWidthMeters;
    final height = width * decoded.height / decoded.width;

    onProgress?.call(null, 'Building the 3D model…');
    final glb = GlbBuilder.texturedQuad(
      png: bytes,
      widthMeters: width,
      heightMeters: height,
    );
    return FileStore.saveBytes(_fileName(sofa), glb);
  }

  String _fileName(Sofa sofa) => '${sofa.id}_${DateTime.now().millisecondsSinceEpoch}.glb';
}
