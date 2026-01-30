import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';

class ContentArea extends StatelessWidget {
  final TextEditingController textController;
  final Uint8List? pastedImage;
  final Uint8List? cachedSyncedImage;
  final String? cachedSyncedImageName;
  final PlatformFile? selectedFile;
  final bool isLoading;
  final VoidCallback onPaste;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onClear;
  final VoidCallback onDownload;
  final VoidCallback onCopy;
  final Function(Uint8List bytes)? onImagePaste;
  
  const ContentArea({
    super.key,
    required this.textController,
    this.pastedImage,
    this.cachedSyncedImage,
    this.cachedSyncedImageName,
    this.selectedFile,
    this.isLoading = false,
    required this.onPaste,
    required this.onPickImage,
    required this.onPickFile,
    required this.onClear,
    required this.onDownload,
    required this.onCopy,
    this.onImagePaste,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, sync, _) {
        final item = sync.currentItem;
        final bool hasImage = pastedImage != null || 
            cachedSyncedImage != null || 
            (item?.isImage == true && item?.binaryContent != null);
        
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
              if (isLoading)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              else
                _buildContent(context, item),
              
              // Action buttons overlay
              Positioned(
                top: 4,
                right: 4,
                child: _ActionButtonsRow(
                  hasImage: hasImage,
                  hasFile: item?.isFile == true,
                  onDownload: onDownload,
                  onPickImage: onPickImage,
                  onPickFile: onPickFile,
                  onClear: onClear,
                  onCopy: onCopy,
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
    
    // Show cached synced image (prevents blinking)
    if (cachedSyncedImage != null) {
      return _ImagePreview(
        bytes: cachedSyncedImage!,
        filename: cachedSyncedImageName ?? 'Image',
      );
    }
    
    // Show synced image from provider
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
    return _TextInput(controller: textController, onImagePaste: onImagePaste);
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final bool hasImage;
  final bool hasFile;
  final VoidCallback onDownload;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onClear;
  final VoidCallback onCopy;
  
  const _ActionButtonsRow({
    required this.hasImage,
    required this.hasFile,
    required this.onDownload,
    required this.onPickImage,
    required this.onPickFile,
    required this.onClear,
    required this.onCopy,
  });
  
  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final buttonSize = isIOS ? 36.0 : 28.0;
    final iconSize = isIOS ? 18.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage || hasFile)
            _ActionButton(
              icon: Platform.isIOS && hasImage ? Icons.photo_library : Icons.download,
              tooltip: Platform.isIOS && hasImage ? 'Save to Photos' : 'Download',
              onPressed: onDownload,
              size: buttonSize,
              iconSize: iconSize,
            ),
          _ActionButton(
            icon: Icons.copy,
            tooltip: 'Copy to Clipboard',
            onPressed: onCopy,
            size: buttonSize,
            iconSize: iconSize,
          ),
          _ActionButton(
            icon: Icons.image,
            tooltip: 'Pick Image',
            onPressed: onPickImage,
            size: buttonSize,
            iconSize: iconSize,
          ),
          _ActionButton(
            icon: Icons.attach_file,
            tooltip: 'Pick File',
            onPressed: onPickFile,
            size: buttonSize,
            iconSize: iconSize,
          ),
          _ActionButton(
            icon: Icons.clear,
            tooltip: 'Clear',
            onPressed: onClear,
            size: buttonSize,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 28,
    this.iconSize = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(4),
          child: Icon(icon, size: iconSize, color: Colors.white),
        ),
      ),
    );
  }
}

class _TextInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(Uint8List bytes)? onImagePaste;
  
  const _TextInput({required this.controller, this.onImagePaste});
  
  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  final FocusNode _focusNode = FocusNode();
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  Future<void> _handleKeyEvent(KeyEvent event) async {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed || 
                           HardwareKeyboard.instance.isMetaPressed;
      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyV) {
        // Try to get image from clipboard
        try {
          final imageBytes = await Pasteboard.image;
          if (imageBytes != null && widget.onImagePaste != null) {
            widget.onImagePaste!(imageBytes);
            return;
          }
        } catch (e) {
          // Fall through to normal paste
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: widget.controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Paste or type text here...\n\nYou can also paste images (Ctrl+V) or use the buttons to attach files.',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
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
              gaplessPlayback: true, // Prevents blinking on rebuild
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
