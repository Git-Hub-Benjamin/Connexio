import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';

class SlotDropdown extends StatelessWidget {
  final Function(String slotId) onSelected;
  
  const SlotDropdown({
    super.key,
    required this.onSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, sync, _) {
        final slots = sync.savedSlots;
        
        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: PopupMenuButton<String>(
            enabled: slots.isNotEmpty,
            onSelected: onSelected,
            offset: Offset(0, -200),
            constraints: BoxConstraints(maxHeight: 250),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                height: 30,
                child: Text(
                  'Saved Slots',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              PopupMenuDivider(height: 1),
              ...slots.map((slot) => PopupMenuItem<String>(
                value: slot.id,
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      _getIconForType(slot.type),
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slot.name,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (slot.preview != null)
                            Text(
                              slot.preview!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(context, sync, slot);
                      },
                    ),
                  ],
                ),
              )),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 14,
                    color: slots.isEmpty ? Colors.white38 : Colors.white70,
                  ),
                  SizedBox(width: 4),
                  Text(
                    slots.isEmpty ? 'No Slots' : '${slots.length} Slots',
                    style: TextStyle(
                      fontSize: 11,
                      color: slots.isEmpty ? Colors.white38 : Colors.white70,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_up,
                    size: 16,
                    color: slots.isEmpty ? Colors.white38 : Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  IconData _getIconForType(SyncItemType type) {
    switch (type) {
      case SyncItemType.text:
        return Icons.text_fields;
      case SyncItemType.image:
        return Icons.image;
      case SyncItemType.file:
        return Icons.attach_file;
    }
  }
  
  void _confirmDelete(BuildContext context, SyncProvider sync, slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Slot'),
        content: Text('Delete "${slot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              sync.deleteSlot(slot.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
