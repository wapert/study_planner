import 'package:flutter/material.dart';
import '../models/calendar_event.dart';

class EventChip extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onDelete;
  const EventChip({super.key, required this.event, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Color(event.type.colorValue);
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(event.title, style: const TextStyle(fontSize: 13)),
      backgroundColor: color.withAlpha(30),
      side: BorderSide(color: color.withAlpha(80)),
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 14) : null,
      onDeleted: onDelete,
    );
  }
}
