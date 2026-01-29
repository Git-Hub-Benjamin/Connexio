import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/settings_provider.dart';
import '../models/sync_item.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/content_area.dart';
import '../widgets/slot_dropdown.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  Uint8List? _pastedImage;
  String? _pastedImageName;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    // Listen for sync changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncProvider = context.read<SyncProvider>();
      syncProvider.addListener(_onSyncUpdate);
    });
  }
  
  void _onSyncUpdate() {
    final syncProvider = context.read<SyncProvider>();
    final item = syncProvider.currentItem;
    
    if (item != null && item.isText && _textController.text != item.textContent) {
      _textController.text = item.textContent ?? '';
    }
    
    if (item != null && item.isImage && item.binaryContent != null) {
      setState(() {
        _pastedImage = item.binaryContent;
        _pastedImageName = item.filename;
      });
    }
  }
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  Future<void> _handlePaste() async {
    // Try to get image from clipboard
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _textController.text = clipboardData!.text!;
        setState(() {
          _pastedImage = null;
          _pastedImageName = null;
          _selectedFile = null;
        });
      }
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _pastedImage = null;
        _pastedImageName = null;
        _textController.clear();
      });
    }
  }
  
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _pastedImage = file.bytes;
        _pastedImageName = file.name;
        _selectedFile = null;
        _textController.clear();
      });
    }
  }
  
  Future<void> _upload() async {
    if (_isUploading) return;
    
    setState(() => _isUploading = true);
    
    final syncProvider = context.read<SyncProvider>();
    bool success = false;
    
    if (_pastedImage != null) {
      success = await syncProvider.uploadImage(
        _pastedImage!,
        _pastedImageName ?? 'image.png',
      );
    } else if (_selectedFile != null && _selectedFile!.bytes != null) {
      success = await syncProvider.uploadFile(
        _selectedFile!.name,
        _selectedFile!.bytes!,
        _selectedFile!.extension ?? 'application/octet-stream',
      );
    } else if (_textController.text.isNotEmpty) {
      success = await syncProvider.uploadText(_textController.text);
    }
    
    setState(() => _isUploading = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  
  Future<void> _save() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _SaveDialog(),
    );
    
    if (name != null && name.isNotEmpty) {
      final syncProvider = context.read<SyncProvider>();
      final success = await syncProvider.saveToSlot(name);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to "$name"'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
  
  void _clearContent() {
    setState(() {
      _textController.clear();
      _pastedImage = null;
      _pastedImageName = null;
      _selectedFile = null;
    });
    context.read<SyncProvider>().clearCurrent();
  }
  
  Future<void> _downloadCurrentFile() async {
    final syncProvider = context.read<SyncProvider>();
    final item = syncProvider.currentItem;
    
    if (item == null) return;
    
    Uint8List? bytes;
    String? filename;
    
    if (item.isImage && item.binaryContent != null) {
      bytes = item.binaryContent;
      filename = item.filename ?? 'image.png';
    } else if (item.isFile && item.fileId != null) {
      bytes = await syncProvider.downloadFile(item.fileId!);
      filename = item.filename ?? 'file';
    }
    
    if (bytes != null && filename != null) {
      String? outputPath;
      
      if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        outputPath = '${dir.path}/$filename';
      } else {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save file',
          fileName: filename,
        );
      }
      
      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to $outputPath'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
  
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header with drag area, connection indicator, and settings
              _buildHeader(),
              
              // Main content area
              Expanded(
                child: ContentArea(
                  textController: _textController,
                  pastedImage: _pastedImage,
                  selectedFile: _selectedFile,
                  onPaste: _handlePaste,
                  onPickImage: _pickImage,
                  onClear: _clearContent,
                  onDownload: _downloadCurrentFile,
                ),
              ),
              
              // Bottom bar with upload, dropdown, and save
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    final isIOS = Platform.isIOS;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          // Window drag - handled by window_manager
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isIOS ? 16 : 12,
          8,
          isIOS ? 16 : 12,
          8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
        ),
        child: Row(
          children: [
            ConnectionIndicator(),
            Expanded(
              child: Center(
                child: Text(
                  'Connexio',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 18),
              padding: EdgeInsets.all(isIOS ? 8 : 0),
              constraints: BoxConstraints(
                minWidth: isIOS ? 44 : 28,
                minHeight: isIOS ? 44 : 28,
              ),
              onPressed: _showSettings,
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomBar() {
    final isIOS = Platform.isIOS;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        isIOS ? 16 : 8,
        8,
        isIOS ? 16 : 8,
        isIOS ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
      ),
      child: Row(
        children: [
          // Upload button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _upload,
              icon: _isUploading 
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.cloud_upload, size: 16),
              label: Text('Upload', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isIOS ? 12 : 8,
                  horizontal: isIOS ? 16 : 8,
                ),
                minimumSize: Size(0, isIOS ? 44 : 32),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          SizedBox(width: isIOS ? 12 : 6),
          
          // Slot dropdown
          Expanded(
            child: SlotDropdown(
              onSelected: (slotId) async {
                final syncProvider = context.read<SyncProvider>();
                await syncProvider.loadFromSlot(slotId);
              },
            ),
          ),
          SizedBox(width: isIOS ? 12 : 6),
          
          // Save button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(Icons.save, size: 16),
              label: Text('Save', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isIOS ? 12 : 8,
                  horizontal: isIOS ? 16 : 8,
                ),
                minimumSize: Size(0, isIOS ? 44 : 32),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveDialog extends StatefulWidget {
  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Save to Slot'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter slot name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text('Save'),
        ),
      ],
    );
  }
}
