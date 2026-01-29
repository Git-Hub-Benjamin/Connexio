import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  String _serverUrl = '';
  double _defaultWindowWidth = 200.0;
  double _defaultWindowHeight = 400.0;
  int _syncIntervalSeconds = 2;
  bool _autoSync = true;
  
  SettingsProvider(this._prefs) {
    _loadSettings();
  }
  
  String get serverUrl => _serverUrl;
  double get defaultWindowWidth => _defaultWindowWidth;
  double get defaultWindowHeight => _defaultWindowHeight;
  int get syncIntervalSeconds => _syncIntervalSeconds;
  bool get autoSync => _autoSync;
  
  void _loadSettings() {
    _serverUrl = _prefs.getString('serverUrl') ?? '';
    _defaultWindowWidth = _prefs.getDouble('windowWidth') ?? 200.0;
    _defaultWindowHeight = _prefs.getDouble('windowHeight') ?? 400.0;
    _syncIntervalSeconds = _prefs.getInt('syncInterval') ?? 2;
    _autoSync = _prefs.getBool('autoSync') ?? true;
    notifyListeners();
  }
  
  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    await _prefs.setString('serverUrl', url);
    notifyListeners();
  }
  
  Future<void> setDefaultWindowSize(double width, double height) async {
    _defaultWindowWidth = width;
    _defaultWindowHeight = height;
    await _prefs.setDouble('windowWidth', width);
    await _prefs.setDouble('windowHeight', height);
    notifyListeners();
  }
  
  Future<void> setSyncInterval(int seconds) async {
    _syncIntervalSeconds = seconds;
    await _prefs.setInt('syncInterval', seconds);
    notifyListeners();
  }
  
  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _prefs.setBool('autoSync', value);
    notifyListeners();
  }
}
