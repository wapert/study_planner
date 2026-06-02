import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/calendar_event.dart';
import '../utils/date_utils.dart';
import '../widgets/session_tile.dart';
import '../widgets/event_chip.dart';

const _uuid = Uuid();

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now().dateOnly;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final sessions = provider.sessionsForDay(_selected);
    final events = provider.eventsForDay(_selected);

    return Scaffold(
      appBar: AppBar(title: const Text('行事曆'), centerTitle: false),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2025, 1, 1),
            lastDay: DateTime(2027, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => d.isSameDay(_selected),
            onDaySelected: (selected, focused) {
              setState(() {
                _selected = selected.dateOnly;
                _focused = focused;
              });
            },
            onPageChanged: (focused) => setState(() => _focused = focused),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              final s = provider.sessionsForDay(day);
              final e = provider.eventsForDay(day);
              return [...s, ...e];
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            locale: 'zh_TW',
            startingDayOfWeek: StartingDayOfWeek.sunday,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (events.isNotEmpty) ...[
                  const Text('活動', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: events.map((e) => EventChip(event: e, onDelete: () {
                      context.read<AppProvider>().deleteEvent(e.id);
                    })).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (sessions.isNotEmpty) ...[
                  const Text('讀書時段', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...sessions.map((s) => SessionTile(session: s)),
                ],
                if (events.isEmpty && sessions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text('這天沒有安排', style: TextStyle(color: Colors.grey[500])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新增活動'),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    EventType selectedType = EventType.exam;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新增活動'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '活動名稱'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EventType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: '類型'),
                items: EventType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.label),
                )).toList(),
                onChanged: (t) => setState(() => selectedType = t!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                context.read<AppProvider>().addEvent(CalendarEvent(
                  id: _uuid.v4(),
                  title: titleCtrl.text.trim(),
                  date: _selected,
                  typeIndex: selectedType.index,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('新增'),
            ),
          ],
        ),
      ),
    );
  }
}
