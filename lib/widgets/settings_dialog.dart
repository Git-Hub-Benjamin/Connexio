import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _serverUrlController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _syncIntervalController;
  late bool _autoSync;
  
  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _serverUrlController = TextEditingController(text: settings.serverUrl);
    _widthController = TextEditingController(
      text: settings.defaultWindowWidth.toInt().toString(),
    );
    _heightController = TextEditingController(
      text: settings.defaultWindowHeight.toInt().toString(),
    );
    _syncIntervalController = TextEditingController(
      text: settings.syncIntervalSeconds.toString(),
    );
    _autoSync = settings.autoSync;
  }
  
  @override
  void dispose() {
    _serverUrlController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _syncIntervalController.dispose();
    super.dispose();
  }
  
  Future<void> _saveSettings() async {
    final settings = context.read<SettingsProvider>();
    
    // Save server URL
    String serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isNotEmpty && !serverUrl.startsWith('http')) {
      serverUrl = 'http://$serverUrl';
    }
    await settings.setServerUrl(serverUrl);
    
    // Save window size
    final width = double.tryParse(_widthController.text) ?? 200;
    final height = double.tryParse(_heightController.text) ?? 400;
    await settings.setDefaultWindowSize(width, height);
    
    // Save sync settings
    final interval = int.tryParse(_syncIntervalController.text) ?? 2;
    await settings.setSyncInterval(interval);
    await settings.setAutoSync(_autoSync);
    
    // Reconnect with new settings
    context.read<SyncProvider>().reconnect();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  
  Future<void> _saveCurrentWindowSize() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final size = await windowManager.getSize();
      _widthController.text = size.width.toInt().toString();
      _heightController.text = size.height.toInt().toString();
      setState(() {});
    }
  }
  
  Future<void> _clearAllSlots() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear All Slots'),
        content: Text('Are you sure you want to delete all saved slots? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final syncProvider = context.read<SyncProvider>();
      await syncProvider.clearAllSlots();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All slots cleared'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, size: 20),
          SizedBox(width: 8),
          Text('Settings'),
        ],
      ),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: 350, // Wider settings dialog
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Configuration
              Text(
                'Server Configuration',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  labelText: 'Server URL (Tailscale IP)',
                  hintText: '100.x.x.x:8080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                  helperText: 'Your homelab Tailscale IP and port',
                ),
              ),
              SizedBox(height: 16),
              
              // Sync Settings
              Text(
                'Sync Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _syncIntervalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sync Interval (seconds)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Auto Sync'),
                subtitle: Text('Automatically poll server for updates'),
                value: _autoSync,
                onChanged: (value) => setState(() => _autoSync = value),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 16),
              
              // Window Settings (desktop only)
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) ...[
              Text(
                'Window Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Width',
                        border: OutlineInputBorder(),
                        suffixText: 'px',
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height',
                        border: OutlineInputBorder(),
                        suffixText: 'px',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saveCurrentWindowSize,
                icon: Icon(Icons.aspect_ratio, size: 16),
                label: Text('Use Current Window Size'),
              ),
              SizedBox(height: 8),
              Text(
                'Tip: Press ESC to close the window',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              SizedBox(height: 16),
              ],
              
              // Data Management
              Text(
                'Data Management',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearAllSlots,
                  icon: Icon(Icons.delete_forever, color: Colors.red),
                  label: Text('Clear All Slots', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: Text('Save'),
        ),
      ],
    );
  }
}
