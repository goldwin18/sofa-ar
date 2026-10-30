import 'dart:convert';
import 'dart:typed_data';

/// Writes a minimal binary glTF (.glb) file by hand, so no 3D library is needed.
class GlbBuilder {
  GlbBuilder._();

  static const _magic = 0x46546C67; // "glTF"
  static const _jsonChunk = 0x4E4F534A; // "JSON"
  static const _binChunk = 0x004E4942; // "BIN\0"

  /// A flat, upright rectangle (bottom edge on the floor) showing [png] on both sides.
  /// Transparent parts of the PNG are cut away. Sizes are in metres.
  static Uint8List texturedQuad({
    required Uint8List png,
    required double widthMeters,
    required double heightMeters,
  }) {
    final half = widthMeters / 2;

    final positions = Float32List.fromList([
      -half, 0, 0,
      half, 0, 0,
      half, heightMeters, 0,
      -half, heightMeters, 0,
    ]);
    final normals = Float32List.fromList([0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1]);
    final uvs = Float32List.fromList([0, 1, 1, 1, 1, 0, 0, 0]);
    final indices = Uint16List.fromList([0, 1, 2, 0, 2, 3]);

    // Binary chunk: every piece starts on a 4-byte boundary, as glTF requires.
    final bin = BytesBuilder();
    final views = <Map<String, dynamic>>[];
    int addView(Uint8List data, {int? target}) {
      views.add({
        'buffer': 0,
        'byteOffset': bin.length,
        'byteLength': data.length,
        if (target != null) 'target': target,
      });
      bin.add(data);
      while (bin.length % 4 != 0) {
        bin.addByte(0);
      }
      return views.length - 1;
    }

    final posView = addView(positions.buffer.asUint8List(), target: 34962);
    final normView = addView(normals.buffer.asUint8List(), target: 34962);
    final uvView = addView(uvs.buffer.asUint8List(), target: 34962);
    final idxView = addView(indices.buffer.asUint8List(), target: 34963);
    final imgView = addView(png);
    final binBytes = bin.toBytes();

    final json = {
      'asset': {'version': '2.0', 'generator': 'sofa_ar'},
      'scene': 0,
      'scenes': [
        {'nodes': [0]}
      ],
      'nodes': [
        {'mesh': 0, 'name': 'SofaCutout'}
      ],
      'meshes': [
        {
          'primitives': [
            {
              'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2},
              'indices': 3,
              'material': 0,
            }
          ]
        }
      ],
      'materials': [
        {
          'pbrMetallicRoughness': {
            'baseColorTexture': {'index': 0},
            'metallicFactor': 0,
            'roughnessFactor': 1,
          },
          'alphaMode': 'MASK',
          'alphaCutoff': 0.5,
          'doubleSided': true,
        }
      ],
      'textures': [
        {'source': 0, 'sampler': 0}
      ],
      'samplers': [
        {'magFilter': 9729, 'minFilter': 9987, 'wrapS': 33071, 'wrapT': 33071}
      ],
      'images': [
        {'bufferView': imgView, 'mimeType': 'image/png'}
      ],
      'accessors': [
        {
          'bufferView': posView,
          'componentType': 5126,
          'count': 4,
          'type': 'VEC3',
          'min': [-half, 0, 0],
          'max': [half, heightMeters, 0],
        },
        {'bufferView': normView, 'componentType': 5126, 'count': 4, 'type': 'VEC3'},
        {'bufferView': uvView, 'componentType': 5126, 'count': 4, 'type': 'VEC2'},
        {'bufferView': idxView, 'componentType': 5123, 'count': 6, 'type': 'SCALAR'},
      ],
      'bufferViews': views,
      'buffers': [
        {'byteLength': binBytes.length}
      ],
    };

    return pack(json, binBytes);
  }

  /// Joins a glTF JSON document and its binary data into one .glb file.
  static Uint8List pack(Map<String, dynamic> json, Uint8List binBytes) {
    final jsonBytes = _padded(utf8.encode(jsonEncode(json)), 0x20);
    final bin = _padded(binBytes, 0x00);
    final total = 12 + 8 + jsonBytes.length + 8 + bin.length;

    final out = BytesBuilder();
    out.add((ByteData(12)
          ..setUint32(0, _magic, Endian.little)
          ..setUint32(4, 2, Endian.little)
          ..setUint32(8, total, Endian.little))
        .buffer
        .asUint8List());
    out.add((ByteData(8)
          ..setUint32(0, jsonBytes.length, Endian.little)
          ..setUint32(4, _jsonChunk, Endian.little))
        .buffer
        .asUint8List());
    out.add(jsonBytes);
    out.add((ByteData(8)
          ..setUint32(0, bin.length, Endian.little)
          ..setUint32(4, _binChunk, Endian.little))
        .buffer
        .asUint8List());
    out.add(bin);
    return out.toBytes();
  }

  static Uint8List _padded(List<int> data, int fill) {
    final extra = (4 - data.length % 4) % 4;
    return Uint8List.fromList([...data, ...List.filled(extra, fill)]);
  }
}
