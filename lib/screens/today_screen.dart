import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../models/todo_item.dart';
import '../models/chapter_plan.dart';
import '../providers/app_provider.dart';
import '../widgets/account_button.dart';
import '../utils/date_utils.dart';

const _uuid = Uuid();

const _weekdayLabels = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
const _weekdayShort = ['一', '二', '三', '四', '五', '六', '日'];

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selected = DateTime.now().dateOnly;

  List<DateTime> get _weekDays {
    final monday = _selected.subtract(Duration(days: _selected.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)).dateOnly);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isToday = _selected.isSameDay(DateTime.now());
    final dateLabel =
        '${_selected.month}/${_selected.day}（${_weekdayLabels[_selected.weekday - 1]}）';

    final todos = provider.todosForDay(_selected);
    final sessions = provider.sessionsForDay(_selected);
    final chapterItems = provider.chapterPlans
        .where((p) => p.activeOn(_selected))
        .map((p) => (p, provider.subjectById(p.subjectId)))
        .where((pair) => pair.$2 != null)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Text(
                    isToday ? '$dateLabel  今天' : dateLabel,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const AccountButton(),
                ],
              ),
            ),

            // ── Day-of-week strip ──────────────────────────────────────────
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: 7,
                itemBuilder: (context, i) {
                  final day = _weekDays[i];
                  final isSelected = day.isSameDay(_selected);
                  final hasSessions = provider.sessionsForDay(day).isNotEmpty ||
                      provider.todosForDay(day).isNotEmpty;

                  return GestureDetector(
                    onTap: () => setState(() => _selected = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _weekdayShort[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasSessions)
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white54
                                    : Colors.black38,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, thickness: 0.8, indent: 20, endIndent: 20),

            // ── Content list ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // ── 待辦事項 ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
                    child: Row(
                      children: [
                        const Text('待辦事項',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        _IconAction(
                          icon: Icons.add_circle_outline,
                          tooltip: '新增待辦',
                          onTap: () => _showTodoSheet(context),
                        ),
                      ],
                    ),
                  ),
                  if (todos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text('今天沒有待辦事項',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    )
                  else
                    ...todos.map((t) => _TodoTile(
                          todo: t,
                          date: _selected,
                          subject: t.subjectId == null
                              ? null
                              : provider.subjectById(t.subjectId!),
                        )),

                  const Divider(
                      height: 24, thickness: 0.6, indent: 20, endIndent: 20),

                  // ── 讀書時段 ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
                    child: Row(
                      children: [
                        const Text('讀書時段',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        _IconAction(
                          icon: Icons.timer_outlined,
                          tooltip: '新增讀書時段',
                          onTap: () => _showSessionSheet(context),
                        ),
                      ],
                    ),
                  ),
                  ...chapterItems.map((pair) => _ChapterDayTile(
                        plan: pair.$1,
                        subject: pair.$2!,
                        date: _selected,
                      )),
                  if (sessions.isEmpty && chapterItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text('今天沒有讀書時段',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    )
                  else
                    ...sessions.map((s) => _SessionTile(
                          session: s,
                          subject: provider.subjectById(s.subjectId),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet: add To-Do ───────────────────────────────────────────────

  void _showTodoSheet(BuildContext context) {
    final provider = context.read<AppProvider>();
    final subjects = provider.subjects;
    final titleCtrl = TextEditingController();
    String? selectedSubjectId;
    // Default: current weekday selected
    final selectedWeekdays = <int>{_selected.weekday};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final selectedColor = selectedSubjectId == null
              ? Colors.black
              : Color(subjects
                  .firstWhere((s) => s.id == selectedSubjectId)
                  .colorValue);

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('新增待辦事項',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Title field
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '待辦事項名稱',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Subject picker
                if (subjects.isNotEmpty) ...[
                  const Text('科目（選填）',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('無'),
                        selected: selectedSubjectId == null,
                        onSelected: (_) =>
                            setModal(() => selectedSubjectId = null),
                      ),
                      ...subjects.map((s) => ChoiceChip(
                            avatar: CircleAvatar(
                                backgroundColor: Color(s.colorValue),
                                radius: 6),
                            label: Text(s.name),
                            selected: selectedSubjectId == s.id,
                            onSelected: (_) =>
                                setModal(() => selectedSubjectId = s.id),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Weekday chips
                const Text('重複星期',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(7, (i) {
                    final wd = i + 1; // 1=Mon
                    final active = selectedWeekdays.contains(wd);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModal(() {
                          if (active) {
                            selectedWeekdays.remove(wd);
                          } else {
                            selectedWeekdays.add(wd);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? selectedColor
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _weekdayShort[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    active ? Colors.white : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setModal(() {
                    if (selectedWeekdays.length == 7) {
                      selectedWeekdays.clear();
                    } else {
                      selectedWeekdays.addAll([1, 2, 3, 4, 5, 6, 7]);
                    }
                  }),
                  child: Row(
                    children: [
                      Icon(
                        selectedWeekdays.length == 7
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      const Text('每天',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: selectedColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      context.read<AppProvider>().addTodo(TodoItem(
                            id: _uuid.v4(),
                            title: title,
                            subjectId: selectedSubjectId,
                            weekdays: selectedWeekdays.toList()..sort(),
                          ));
                      Navigator.pop(ctx);
                    },
                    child: const Text('新增', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Bottom sheet: add Study Session ──────────────────────────────────────

  void _showSessionSheet(BuildContext context) {
    final provider = context.read<AppProvider>();
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先到「科目」頁新增科目')),
      );
      return;
    }

    String selectedSubjectId = subjects.first.id;
    int startHour = 8, startMinute = 0, duration = 60;
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final color = Color(subjects
              .firstWhere((s) => s.id == selectedSubjectId)
              .colorValue);

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('新增讀書時段',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                const Text('科目',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects
                      .map((s) => ChoiceChip(
                            avatar: CircleAvatar(
                                backgroundColor: Color(s.colorValue),
                                radius: 6),
                            label: Text(s.name),
                            selected: selectedSubjectId == s.id,
                            onSelected: (_) =>
                                setModal(() => selectedSubjectId = s.id),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                _SheetRow(
                  label: '開始時間',
                  value: formatHHMM(startHour, startMinute),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime:
                          TimeOfDay(hour: startHour, minute: startMinute),
                    );
                    if (t != null) {
                      setModal(() {
                        startHour = t.hour;
                        startMinute = t.minute;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                _SheetRow(
                  label: '時長',
                  value: formatDuration(duration),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    _StepButton(
                      icon: Icons.remove,
                      onTap: duration > 15
                          ? () => setModal(() => duration -= 15)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(formatDuration(duration),
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    _StepButton(
                      icon: Icons.add,
                      onTap: () => setModal(() => duration += 15),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: '備註（選填）',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.read<AppProvider>().addSession(StudySession(
                            id: _uuid.v4(),
                            subjectId: selectedSubjectId,
                            date: _selected,
                            startHour: startHour,
                            startMinute: startMinute,
                            durationMinutes: duration,
                            note: noteCtrl.text.trim(),
                          ));
                      Navigator.pop(ctx);
                    },
                    child: const Text('新增', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Chapter day tile ─────────────────────────────────────────────────────────

class _ChapterDayTile extends StatelessWidget {
  final ChapterPlan plan;
  final Subject subject;
  final DateTime date;

  const _ChapterDayTile({
    required this.plan,
    required this.subject,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);
    final done = plan.isCompletedOn(date);
    final rangeLabel = '${plan.versionPrefix}${plan.rangeLabelForDate(date)}';

    return InkWell(
      onTap: () => context.read<AppProvider>().toggleChapterDay(plan, date),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: done ? color : Colors.transparent,
                border: Border.all(
                  color: done ? color : Colors.grey.shade400,
                  width: 1.8,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: done
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Icon(Icons.menu_book_outlined,
                size: 14,
                color: done ? Colors.grey.shade400 : color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${subject.name}  ·  $rangeLabel',
                style: TextStyle(
                  fontSize: 15,
                  color: done ? Colors.grey.shade400 : Colors.black87,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Todo tile ─────────────────────────────────────────────────────────────────

class _TodoTile extends StatelessWidget {
  final TodoItem todo;
  final DateTime date;
  final Subject? subject;

  const _TodoTile({
    required this.todo,
    required this.date,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final done = todo.isCompletedOn(date);
    final color =
        subject != null ? Color(subject!.colorValue) : Colors.grey.shade700;

    return Dismissible(
      key: Key('todo-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade50,
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('刪除待辦'),
                content: Text('確定刪除「${todo.title}」？\n（所有星期的此項目都會刪除）'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消')),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('刪除'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) =>
          context.read<AppProvider>().deleteTodo(todo.id),
      child: InkWell(
        onTap: () => context.read<AppProvider>().toggleTodo(todo, date),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              // Custom checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: done ? color : Colors.transparent,
                  border: Border.all(
                    color: done ? color : Colors.grey.shade400,
                    width: 1.8,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 15,
                        color: done ? Colors.grey.shade400 : Colors.black87,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (subject != null) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subject!.name,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        _WeekdayBadges(weekdays: todo.weekdays, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Study session tile ────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final StudySession session;
  final Subject? subject;
  const _SessionTile({required this.session, required this.subject});

  @override
  Widget build(BuildContext context) {
    final done = session.isCompleted;
    final color =
        subject != null ? Color(subject!.colorValue) : Colors.grey;

    return Dismissible(
      key: Key('session-${session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade50,
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) =>
          context.read<AppProvider>().deleteSession(session.id),
      child: InkWell(
        onTap: () => context.read<AppProvider>().toggleSession(session),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: done ? color : Colors.transparent,
                  border: Border.all(
                    color: done ? color : Colors.grey.shade400,
                    width: 1.8,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    if (subject != null) ...[
                      Container(
                          width: 4, height: 16,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.timer_outlined, size: 14,
                        color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${subject?.name ?? '已刪除科目'}  ${formatHHMM(session.startHour, session.startMinute)}  ${formatDuration(session.durationMinutes)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: done ? Colors.grey.shade400 : Colors.black87,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (session.note.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.note,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weekday badge row ─────────────────────────────────────────────────────────

class _WeekdayBadges extends StatelessWidget {
  final List<int> weekdays;
  final Color color;
  const _WeekdayBadges({required this.weekdays, required this.color});

  @override
  Widget build(BuildContext context) {
    if (weekdays.isEmpty || weekdays.length == 7) {
      return Text('每天',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: weekdays.map((wd) {
        return Container(
          margin: const EdgeInsets.only(right: 3),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _weekdayShort[wd - 1],
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _SheetRow(
      {required this.label,
      required this.value,
      this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.black54)),
            const Spacer(),
            trailing ??
                Text(value,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.grey.shade200
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null
                ? Colors.black87
                : Colors.grey.shade400),
      ),
    );
  }
}
