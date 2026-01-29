import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';

class ContentArea extends StatelessWidget {
  final TextEditingController textController;
  final Uint8List? pastedImage;
  final PlatformFile? selectedFile;
  final VoidCallback onPaste;
  final VoidCallback onPickImage;
  final VoidCallback onClear;
  final VoidCallback onDownload;
  
  const ContentArea({
    super.key,
    required this.textController,
    this.pastedImage,
    this.selectedFile,
    required this.onPaste,
    required this.onPickImage,
    required this.onClear,
    required this.onDownload,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, sync, _) {
        final item = sync.currentItem;
        
        return Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Stack(
            children: [
              // Content
              _buildContent(context, item),
              
              // Action buttons overlay
              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item?.isImage == true || item?.isFile == true)
                      _ActionButton(
                        icon: Icons.download,
                        tooltip: 'Download',
                        onPressed: onDownload,
                      ),
                    _ActionButton(
                      icon: Icons.image,
                      tooltip: 'Pick Image',
                      onPressed: onPickImage,
                    ),
                    _ActionButton(
                      icon: Icons.clear,
                      tooltip: 'Clear',
                      onPressed: onClear,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildContent(BuildContext context, SyncItem? syncItem) {
    // Show pasted image
    if (pastedImage != null) {
      return _ImagePreview(
        bytes: pastedImage!,
        filename: 'Pasted Image',
      );
    }
    
    // Show selected file
    if (selectedFile != null) {
      return _FilePreview(file: selectedFile!);
    }
    
    // Show synced image
    if (syncItem?.isImage == true && syncItem?.binaryContent != null) {
      return _ImagePreview(
        bytes: syncItem!.binaryContent!,
        filename: syncItem.filename ?? 'Image',
      );
    }
    
    // Show synced file indicator
    if (syncItem?.isFile == true) {
      return _SyncedFilePreview(item: syncItem!);
    }
    
    // Default: text input
    return _TextInput(controller: textController);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  
  const _TextInput({required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Paste or type text here...\n\nYou can also paste images or use the buttons to attach files.',
        hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List bytes;
  final String filename;
  
  const _ImagePreview({
    required this.bytes,
    required this.filename,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            filename,
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _FilePreview extends StatelessWidget {
  final PlatformFile file;
  
  const _FilePreview({required this.file});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(file.extension),
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 8),
          Text(
            file.name,
            style: TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            _formatSize(file.size),
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
  
  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'mkv':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _SyncedFilePreview extends StatelessWidget {
  final SyncItem item;
  
  const _SyncedFilePreview({required this.item});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_download,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(height: 8),
          Text(
            item.filename ?? 'File',
            style: TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Tap download to save',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
