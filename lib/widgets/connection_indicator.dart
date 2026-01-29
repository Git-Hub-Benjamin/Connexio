import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, sync, _) {
        Color color;
        String tooltip;
        IconData icon;
        
        switch (sync.status) {
          case ConnectionStatus.connected:
            color = Colors.green;
            tooltip = 'Connected';
            icon = Icons.cloud_done;
            break;
          case ConnectionStatus.connecting:
            color = Colors.orange;
            tooltip = 'Connecting...';
            icon = Icons.cloud_sync;
            break;
          case ConnectionStatus.error:
            color = Colors.red;
            tooltip = 'Error: ${sync.errorMessage ?? "Connection failed"}';
            icon = Icons.cloud_off;
            break;
          case ConnectionStatus.disconnected:
          default:
            color = Colors.grey;
            tooltip = 'Disconnected - Configure server in settings';
            icon = Icons.cloud_outlined;
        }
        
        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: () => sync.reconnect(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                icon,
                size: 12,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
