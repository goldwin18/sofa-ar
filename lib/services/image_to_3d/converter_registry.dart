import '../settings_service.dart';
import 'cutout_converter.dart';
import 'image_to_3d_service.dart';
import 'meshy_converter.dart';

/// The list of conversion options shown to the user.
class ConverterRegistry {
  ConverterRegistry._();

  static List<ImageTo3dService> build(SettingsService settings) => [
        CutoutConverter(),
        MeshyConverter(apiKey: settings.meshyApiKey),
      ];
}
