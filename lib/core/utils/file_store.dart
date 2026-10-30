import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Saves and removes the files the user creates (sofa photos and 3D models).
class FileStore {
  FileStore._();

  static Future<Directory> _folder() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/sofas');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Writes [bytes] to a file called [fileName] and returns the full path.
  static Future<String> saveBytes(String fileName, Uint8List bytes) async {
    final file = File('${(await _folder()).path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
