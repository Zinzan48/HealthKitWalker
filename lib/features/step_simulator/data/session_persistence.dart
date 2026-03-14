import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/session_config.dart';
import '../domain/session_snapshot.dart';

class SessionPersistence {
  SessionPersistence(this._preferences);

  static const _configKey = 'step_simulator_config';
  static const _snapshotKey = 'step_simulator_snapshot';

  final SharedPreferences _preferences;

  Future<void> saveConfig(SessionConfig config) async {
    await _preferences.setString(_configKey, jsonEncode(config.toJson()));
  }

  SessionConfig loadConfig() {
    final raw = _preferences.getString(_configKey);
    if (raw == null || raw.isEmpty) {
      return SessionConfig.defaults();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return SessionConfig.fromJson(decoded);
  }

  Future<void> saveSnapshot(SessionSnapshot snapshot) async {
    await _preferences.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
  }

  SessionSnapshot? loadSnapshot() {
    final raw = _preferences.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return SessionSnapshot.fromJson(decoded);
  }

  Future<void> clearSnapshot() async {
    await _preferences.remove(_snapshotKey);
  }
}
