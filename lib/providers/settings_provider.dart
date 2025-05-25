import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsProvider with ChangeNotifier {
  static const String _settingsKey = 'app_settings';
  final SharedPreferences _prefs;
  Settings _settings;

  SettingsProvider(this._prefs)
      : _settings = Settings() {
    _loadSettings();
  }

  Settings get settings => _settings;

  Future<void> _loadSettings() async {
    final String? settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        _settings = Settings.fromJson(json.decode(settingsJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    await _prefs.setString(_settingsKey, json.encode(_settings.toJson()));
  }

  Future<void> updateSlideshowInterval(SlideshowInterval interval) async {
    _settings = _settings.copyWith(slideshowInterval: interval);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleAudio(bool enabled) async {
    _settings = _settings.copyWith(isAudioEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateAudioTrack(AudioTrack track) async {
    _settings = _settings.copyWith(selectedTrack: track);
    await _saveSettings();
    notifyListeners();
  }
} 