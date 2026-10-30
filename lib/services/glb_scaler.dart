import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'glb_builder.dart';

/// Resizes a .glb so its widest horizontal side is a chosen real-world size.
/// Needed because AI-generated models come in arbitrary units and AR shows true size.
class GlbScaler {
  GlbScaler._();

  static Uint8List fitToWidth(Uint8List glb, double targetWidthMeters) {
    try {
      return _fit(glb, targetWidthMeters);
    } catch (_) {
      // If anything about the file is unexpected, keep it as it came.
      return glb;
    }
  }

  static Uint8List _fit(Uint8List glb, double targetWidth) {
    final header = ByteData.sublistView(glb);
    final jsonLength = header.getUint32(12, Endian.little);
    final jsonEnd = 20 + jsonLength;

    final json = jsonDecode(utf8.decode(glb.sublist(20, jsonEnd))) as Map<String, dynamic>;

    // The binary chunk header (8 bytes) is followed by the data.
    final binLength = header.getUint32(jsonEnd, Endian.little);
    final bin = Uint8List.sublistView(glb, jsonEnd + 8, jsonEnd + 8 + binLength);

    final extent = _widestHorizontalSide(json);
    if (extent == null || extent <= 0) return glb;
    final factor = targetWidth / extent;

    // Wrap the old scene roots in a new node that carries the scale.
    final nodes = json['nodes'] as List<dynamic>;
    final scenes = json['scenes'] as List<dynamic>;
    final scene = scenes[(json['scene'] as int?) ?? 0] as Map<String, dynamic>;
    nodes.add({
      'name': 'FitToWidth',
      'children': List<dynamic>.from(scene['nodes'] as List<dynamic>),
      'scale': [factor, factor, factor],
    });
    scene['nodes'] = [nodes.length - 1];

    return GlbBuilder.pack(json, Uint8List.fromList(bin));
  }

  /// Looks at every mesh position range and returns max(width, depth) of the whole model.
  static double? _widestHorizontalSide(Map<String, dynamic> json) {
    final accessors = json['accessors'] as List<dynamic>;
    final meshes = json['meshes'] as List<dynamic>;
    double? minX, maxX, minZ, maxZ;

    for (final mesh in meshes) {
      for (final primitive in (mesh as Map<String, dynamic>)['primitives'] as List<dynamic>) {
        final attributes = (primitive as Map<String, dynamic>)['attributes'] as Map<String, dynamic>;
        final index = attributes['POSITION'] as int?;
        if (index == null) continue;
        final accessor = accessors[index] as Map<String, dynamic>;
        final min = (accessor['min'] as List<dynamic>?)?.cast<num>();
        final max = (accessor['max'] as List<dynamic>?)?.cast<num>();
        if (min == null || max == null) continue;
        minX = math.min(minX ?? min[0].toDouble(), min[0].toDouble());
        maxX = math.max(maxX ?? max[0].toDouble(), max[0].toDouble());
        minZ = math.min(minZ ?? min[2].toDouble(), min[2].toDouble());
        maxZ = math.max(maxZ ?? max[2].toDouble(), max[2].toDouble());
      }
    }
    if (minX == null || maxX == null || minZ == null || maxZ == null) return null;
    return math.max(maxX - minX, maxZ - minZ);
  }
}
