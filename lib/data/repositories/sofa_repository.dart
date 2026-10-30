import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_store.dart';
import '../models/sofa.dart';
import '../sample_sofas.dart';

/// Holds every sofa (samples + the ones the user added) and saves the user's list on the phone.
class SofaRepository extends ChangeNotifier {
  final List<Sofa> _userSofas = [];

  /// User sofas first, so newly added items are easy to find.
  List<Sofa> get all => [..._userSofas, ...SampleSofas.all];

  Sofa? byId(String id) {
    for (final sofa in all) {
      if (sofa.id == id) return sofa;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefsUserSofas);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _userSofas
        ..clear()
        ..addAll(list.map((e) => Sofa.fromJson(e as Map<String, dynamic>)));
    }
    notifyListeners();
  }

  Future<void> add(Sofa sofa) async {
    _userSofas.insert(0, sofa);
    await _save();
  }

  /// Stores the freshly generated 3D model on a user sofa (replacing the old one).
  Future<void> attachModel(String sofaId, String modelPath) async {
    final index = _userSofas.indexWhere((s) => s.id == sofaId);
    if (index == -1) return;
    final old = _userSofas[index].modelPath;
    _userSofas[index] = _userSofas[index].copyWith(modelPath: modelPath);
    if (old != null && old != modelPath) await FileStore.deleteIfExists(old);
    await _save();
  }

  Future<void> remove(String sofaId) async {
    final index = _userSofas.indexWhere((s) => s.id == sofaId);
    if (index == -1) return;
    final sofa = _userSofas.removeAt(index);
    await FileStore.deleteIfExists(sofa.imagePath);
    await FileStore.deleteIfExists(sofa.modelPath);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefsUserSofas,
      jsonEncode(_userSofas.map((s) => s.toJson()).toList()),
    );
    notifyListeners();
  }
}
