import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';
import '../models/sync_item.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SyncProvider extends ChangeNotifier {
  SettingsProvider? _settings;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  SyncItem? _currentItem;
  List<SavedSlot> _savedSlots = [];
  Timer? _syncTimer;
  String? _errorMessage;
  
  ConnectionStatus get status => _status;
  SyncItem? get currentItem => _currentItem;
  List<SavedSlot> get savedSlots => _savedSlots;
  String? get errorMessage => _errorMessage;
  
  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    if (settings.serverUrl.isNotEmpty) {
      _startSync();
    }
  }
  
  void _startSync() {
    _syncTimer?.cancel();
    if (_settings?.autoSync == true && _settings?.serverUrl.isNotEmpty == true) {
      _checkConnection();
      _syncTimer = Timer.periodic(
        Duration(seconds: _settings?.syncIntervalSeconds ?? 2),
        (_) => _fetchCurrentItem(),
      );
    }
  }
  
  Future<void> _checkConnection() async {
    if (_settings?.serverUrl.isEmpty == true) {
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      return;
    }
    
    _status = ConnectionStatus.connecting;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('${_settings!.serverUrl}/health'),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _status = ConnectionStatus.connected;
        _errorMessage = null;
        _fetchSavedSlots();
      } else {
        _status = ConnectionStatus.error;
        _errorMessage = 'Server returned ${response.statusCode}';
      }
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
  
  Future<void> reconnect() async {
    await _checkConnection();
    if (_status == ConnectionStatus.connected) {
      _startSync();
    }
  }
  
  Future<void> _fetchCurrentItem() async {
    if (_status != ConnectionStatus.connected || _settings?.serverUrl.isEmpty == true) {
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${_settings!.serverUrl}/current'),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['type'] != null) {
          _currentItem = SyncItem.fromJson(data);
        } else {
          _currentItem = null;
        }
        notifyListeners();
      }
    } catch (e) {
      // Silent fail for periodic sync
    }
  }
  
  Future<void> _fetchSavedSlots() async {
    if (_settings?.serverUrl.isEmpty == true) return;
    
    try {
      final response = await http.get(
        Uri.parse('${_settings!.serverUrl}/slots'),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _savedSlots = data.map((e) => SavedSlot.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  Future<bool> uploadText(String text) async {
    if (_settings?.serverUrl.isEmpty == true) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${_settings!.serverUrl}/current'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'text',
          'content': text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        await _fetchCurrentItem();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }
  
  Future<bool> uploadFile(String filename, Uint8List bytes, String mimeType) async {
    if (_settings?.serverUrl.isEmpty == true) return false;
    
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_settings!.serverUrl}/upload'),
      );
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));
      
      final streamedResponse = await request.send().timeout(Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        await _fetchCurrentItem();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }
  
  Future<bool> uploadImage(Uint8List bytes, String filename) async {
    if (_settings?.serverUrl.isEmpty == true) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${_settings!.serverUrl}/current'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'image',
          'content': base64Encode(bytes),
          'filename': filename,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        await _fetchCurrentItem();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }
  
  Future<bool> saveToSlot(String name) async {
    if (_settings?.serverUrl.isEmpty == true || _currentItem == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${_settings!.serverUrl}/slots'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'item': _currentItem!.toJson(),
        }),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        await _fetchSavedSlots();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }
  
  Future<bool> loadFromSlot(String slotId) async {
    if (_settings?.serverUrl.isEmpty == true) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${_settings!.serverUrl}/slots/$slotId/load'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        await _fetchCurrentItem();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }
  
  Future<bool> deleteSlot(String slotId) async {
    if (_settings?.serverUrl.isEmpty == true) return false;
    
    try {
      final response = await http.delete(
        Uri.parse('${_settings!.serverUrl}/slots/$slotId'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        await _fetchSavedSlots();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }
  
  Future<Uint8List?> downloadFile(String fileId) async {
    if (_settings?.serverUrl.isEmpty == true) return null;
    
    try {
      final response = await http.get(
        Uri.parse('${_settings!.serverUrl}/files/$fileId'),
      ).timeout(Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return null;
  }
  
  void clearCurrent() {
    _currentItem = null;
    notifyListeners();
    // Also clear on server
    if (_settings?.serverUrl.isNotEmpty == true) {
      http.delete(Uri.parse('${_settings!.serverUrl}/current')).catchError((_) {});
    }
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
