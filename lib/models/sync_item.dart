import 'dart:convert';
import 'dart:typed_data';

enum SyncItemType { text, image, file }

class SyncItem {
  final SyncItemType type;
  final String? textContent;
  final Uint8List? binaryContent;
  final String? filename;
  final String? mimeType;
  final String? fileId;
  final DateTime timestamp;
  
  SyncItem({
    required this.type,
    this.textContent,
    this.binaryContent,
    this.filename,
    this.mimeType,
    this.fileId,
    required this.timestamp,
  });
  
  factory SyncItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = SyncItemType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => SyncItemType.text,
    );
    
    Uint8List? binary;
    if (json['content'] != null && type != SyncItemType.text) {
      try {
        binary = base64Decode(json['content']);
      } catch (_) {}
    }
    
    return SyncItem(
      type: type,
      textContent: type == SyncItemType.text ? json['content'] : null,
      binaryContent: binary,
      filename: json['filename'],
      mimeType: json['mimeType'],
      fileId: json['fileId'],
      timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'content': type == SyncItemType.text 
        ? textContent 
        : (binaryContent != null ? base64Encode(binaryContent!) : null),
      'filename': filename,
      'mimeType': mimeType,
      'fileId': fileId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  bool get isText => type == SyncItemType.text;
  bool get isImage => type == SyncItemType.image;
  bool get isFile => type == SyncItemType.file;
}

class SavedSlot {
  final String id;
  final String name;
  final SyncItemType type;
  final DateTime savedAt;
  final String? preview;
  
  SavedSlot({
    required this.id,
    required this.name,
    required this.type,
    required this.savedAt,
    this.preview,
  });
  
  factory SavedSlot.fromJson(Map<String, dynamic> json) {
    return SavedSlot(
      id: json['id'],
      name: json['name'],
      type: SyncItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncItemType.text,
      ),
      savedAt: DateTime.parse(json['savedAt']),
      preview: json['preview'],
    );
  }
}
