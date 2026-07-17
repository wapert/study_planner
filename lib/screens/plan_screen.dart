import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/study_session.dart';
import '../utils/date_utils.dart';
import '../widgets/session_tile.dart';
import '../widgets/chapter_plan_sheet.dart';

const _uuid = Uuid();

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _weekStart = DateTime.now().weekStart;

  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('讀書計畫'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _weekStart =
                _weekStart.subtract(const Duration(days: 7))),
          ),
          TextButton(
            onPressed: () =>
                setState(() => _weekStart = DateTime.now().weekStart),
            child: const Text('本週'),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() =>
                _weekStart = _weekStart.add(const Duration(days: 7))),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 7,
        itemBuilder: (context, i) {
          final day = _weekStart.add(Duration(days: i));
          final sessions = provider.sessionsForDay(day);
          final isToday = day.isSameDay(DateTime.now());

          // Chapter plans active on this day
          final chapterItems = provider.chapterPlans
              .where((p) => p.isStudyDay(day))
              .map((p) => (p, provider.subjectById(p.subjectId)))
              .where((pair) => pair.$2 != null)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Day header ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: isToday
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withAlpha(100)
                    : null,
                child: Row(
                  children: [
                    Text(
                      '${_weekdays[day.weekday % 7]}  ${day.month}/${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const Spacer(),
                    // Add chapter plan
                    IconButton(
                      icon: const Icon(Icons.menu_book_outlined, size: 19),
                      tooltip: '新增章節計畫',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _showAddChapterPlan(context, day),
                    ),
                    // Add session
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: '新增讀書時段',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _showAddSessionDialog(context, day),
                    ),
                  ],
                ),
              ),

              // ── Chapter assignments for this day ──────────────────────
              if (chapterItems.isNotEmpty)
                ...chapterItems.map((pair) {
                  final plan = pair.$1;
                  final subject = pair.$2!;
                  final chapCount = plan.chaptersForDate(day);
                  final done = plan.isCompletedOn(day);
                  final color = Color(subject.colorValue);

                  return InkWell(
                    onTap: () =>
                        provider.toggleChapterDay(plan, day),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 4, 16, 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.menu_book_outlined,
                              size: 15,
                              color: done
                                  ? Colors.grey.shade400
                                  : color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${subject.name}  ·  $chapCount 課／頁',
                              style: TextStyle(
                                fontSize: 14,
                                color: done
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          // Completion indicator
                          AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: done
                                  ? color
                                  : Colors.transparent,
                              border: Border.all(
                                color: done
                                    ? color
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              borderRadius:
                                  BorderRadius.circular(5),
                            ),
                            child: done
                                ? const Icon(Icons.check,
                                    size: 13,
                                    color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 4),
                          // Edit plan
                          GestureDetector(
                            onTap: () => showChapterPlanSheet(
                                context, subject,
                                existing: plan),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined,
                                  size: 15,
                                  color: Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              // ── Study sessions for this day ───────────────────────────
              if (sessions.isEmpty && chapterItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text('無安排',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13)),
                )
              else
                ...sessions
                    .map((s) => SessionTile(session: s, showDate: false)),

              const Divider(height: 1),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddSessionDialog(context, DateTime.now()),
        icon: const Icon(Icons.timer_outlined),
        label: const Text('新增時段'),
      ),
    );
  }

  /// Opens a subject picker, then the chapter plan sheet pre-set to [day]'s weekday.
  void _showAddChapterPlan(BuildContext context, DateTime day) {
    final provider = context.read<AppProvider>();
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先新增科目')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('選擇科目'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: subjects.map((s) {
              final existing = provider.chapterPlanForSubject(s.id);
              return ListTile(
                leading: CircleAvatar(
                    backgroundColor: Color(s.colorValue), radius: 10),
                title: Text(s.name),
                subtitle: existing != null
                    ? Text('已設定：每週 ${existing.weeklyChapters} 課／頁',
                        style: const TextStyle(fontSize: 12))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  showChapterPlanSheet(context, s,
                      existing: existing,
                      preselectedDay: day.weekday);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
        ],
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context, DateTime date) {
    final provider = context.read<AppProvider>();
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先新增科目')));
      return;
    }

    String selectedSubjectId = subjects.first.id;
    int startHour = 8;
    int startMinute = 0;
    int duration = 60;
    final noteCtrl = TextEditingController();
    DateTime selectedDate = date;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新增讀書時段'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration:
                      const InputDecoration(labelText: '科目'),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Row(children: [
                              Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(s.colorValue),
                                    shape: BoxShape.circle,
                                  )),
                              const SizedBox(width: 8),
                              Text(s.name),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedSubjectId = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('日期'),
                  trailing: Text(
                      '${selectedDate.month}/${selectedDate.day}'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (d != null) {
                      setState(() => selectedDate = d.dateOnly);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('開始時間'),
                  trailing:
                      Text(formatHHMM(startHour, startMinute)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay(
                          hour: startHour,
                          minute: startMinute),
                    );
                    if (t != null) {
                      setState(() {
                        startHour = t.hour;
                        startMinute = t.minute;
                      });
                    }
                  },
                ),
                Row(
                  children: [
                    const Text('時長（分鐘）'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: duration > 15
                          ? () => setState(() => duration -= 15)
                          : null,
                    ),
                    Text('$duration'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          setState(() => duration += 15),
                    ),
                  ],
                ),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                      labelText: '備註（選填）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              onPressed: () {
                provider.addSession(StudySession(
                  id: _uuid.v4(),
                  subjectId: selectedSubjectId,
                  date: selectedDate,
                  startHour: startHour,
                  startMinute: startMinute,
                  durationMinutes: duration,
                  note: noteCtrl.text.trim(),
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
