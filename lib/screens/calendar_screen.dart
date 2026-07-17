import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/calendar_event.dart';
import '../models/chapter_plan.dart';
import '../utils/date_utils.dart';
import '../widgets/session_tile.dart';
import '../widgets/event_chip.dart';
import '../widgets/chapter_plan_sheet.dart';

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

    // Chapter plans active on the selected day (plan, rangeLabel)
    final chapterItems = _chapterItemsForDay(provider, _selected);

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
            onPageChanged: (focused) =>
                setState(() => _focused = focused),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              final s = provider.sessionsForDay(day);
              final e = provider.eventsForDay(day);
              final c = _chapterItemsForDay(provider, day);
              return [...s, ...e, ...c];
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
                formatButtonVisible: false, titleCentered: true),
            locale: 'zh_TW',
            startingDayOfWeek: StartingDayOfWeek.sunday,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ── Chapter plan items ──────────────────────────────────
                if (chapterItems.isNotEmpty) ...[
                  const Text('章節計畫',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...chapterItems.map((item) =>
                      _ChapterCalendarTile(
                        plan: item.$1,
                        subject: provider
                            .subjectById(item.$1.subjectId),
                        date: _selected,
                        rangeLabel: item.$2,
                        onToggle: () => provider.toggleChapterDay(
                            item.$1, _selected),
                        onEdit: () {
                          final s = provider
                              .subjectById(item.$1.subjectId);
                          if (s != null) {
                            showChapterPlanSheet(context, s,
                                existing: item.$1);
                          }
                        },
                      )),
                  const SizedBox(height: 12),
                ],

                // ── Calendar events ─────────────────────────────────────
                if (events.isNotEmpty) ...[
                  const Text('活動',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: events
                        .map((e) => EventChip(
                              event: e,
                              onDelete: () =>
                                  context
                                      .read<AppProvider>()
                                      .deleteEvent(e.id),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Study sessions ──────────────────────────────────────
                if (sessions.isNotEmpty) ...[
                  const Text('讀書時段',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...sessions.map((s) => SessionTile(session: s)),
                ],

                if (chapterItems.isEmpty &&
                    events.isEmpty &&
                    sessions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text('這天沒有安排',
                          style: TextStyle(
                              color: Colors.grey.shade500)),
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

  /// Returns (ChapterPlan, rangeLabel) tuples active on [day].
  List<(ChapterPlan, String)> _chapterItemsForDay(
      AppProvider provider, DateTime day) {
    final result = <(ChapterPlan, String)>[];
    for (final plan in provider.chapterPlans) {
      if (plan.isStudyDay(day)) {
        result.add((plan, plan.rangeLabelForDate(day)));
      }
    }
    return result;
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
                decoration:
                    const InputDecoration(labelText: '活動名稱'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EventType>(
                initialValue: selectedType,
                decoration:
                    const InputDecoration(labelText: '類型'),
                items: EventType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (t) =>
                    setState(() => selectedType = t!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
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

// ── Chapter item tile in calendar detail ──────────────────────────────────────

class _ChapterCalendarTile extends StatelessWidget {
  final ChapterPlan plan;
  final dynamic subject;
  final DateTime date;
  final String rangeLabel;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _ChapterCalendarTile({
    required this.plan,
    required this.subject,
    required this.date,
    required this.rangeLabel,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (subject == null) return const SizedBox.shrink();
    final done = plan.isCompletedOn(date);
    final color = Color(subject.colorValue as int);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Completion checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? color : Colors.transparent,
                  border: Border.all(
                    color:
                        done ? color : Colors.grey.shade400,
                    width: 1.8,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: done
                    ? const Icon(Icons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                  backgroundColor: color, radius: 6),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${subject.name}  ·  $rangeLabel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: done
                        ? Colors.grey.shade400
                        : Colors.black87,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: Colors.grey),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
