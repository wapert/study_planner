import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../models/todo_item.dart';
import '../providers/app_provider.dart';
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
    final subjects = provider.subjects;
    final isToday = _selected.isSameDay(DateTime.now());
    final dateLabel =
        '${_selected.month}/${_selected.day}（${_weekdayLabels[_selected.weekday - 1]}）';
    final generalTodos = provider.generalTodosForDay(_selected);

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
                  // Add general (no-subject) todo
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: '新增一般待辦',
                    onPressed: () => _showTodoSheet(context, null),
                  ),
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
                  // General todos (no subject)
                  if (generalTodos.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Text('一般待辦',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8)),
                    ),
                    ...generalTodos.map((t) => _TodoTile(
                          todo: t,
                          date: _selected,
                          color: Colors.grey.shade700,
                        )),
                    const Divider(
                        height: 1,
                        thickness: 0.6,
                        indent: 20,
                        endIndent: 20),
                  ],

                  // Subject rows
                  if (subjects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: Text('請先到「科目」頁新增科目')),
                    )
                  else
                    ...subjects.map((s) => _SubjectSection(
                          subject: s,
                          date: _selected,
                          onAddTodo: () => _showTodoSheet(context, s),
                          onAddSession: () =>
                              _showSessionSheet(context, s),
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

  void _showTodoSheet(BuildContext context, Subject? subject) {
    final titleCtrl = TextEditingController();
    // Default: current weekday selected
    final selectedWeekdays = <int>{_selected.weekday};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
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
              // Header
              Row(
                children: [
                  if (subject != null) ...[
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Color(subject.colorValue),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    subject != null ? '${subject.name}  待辦事項' : '新增待辦事項',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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
                              ? (subject != null
                                  ? Color(subject.colorValue)
                                  : Colors.black)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _weekdayShort[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : Colors.black54,
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
                    backgroundColor:
                        subject != null ? Color(subject.colorValue) : Colors.black,
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
                          subjectId: subject?.id,
                          weekdays: selectedWeekdays.toList()..sort(),
                        ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('新增', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom sheet: add Study Session ──────────────────────────────────────

  void _showSessionSheet(BuildContext context, Subject subject) {
    int startHour = 8, startMinute = 0, duration = 60;
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: Color(subject.colorValue),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(subject.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('讀書時段',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 20),
              _SheetRow(
                label: '開始時間',
                value: formatHHMM(startHour, startMinute),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay(hour: startHour, minute: startMinute),
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
                    backgroundColor: Color(subject.colorValue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    context.read<AppProvider>().addSession(StudySession(
                          id: _uuid.v4(),
                          subjectId: subject.id,
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
        ),
      ),
    );
  }
}

// ── Subject section with todos + sessions ─────────────────────────────────────

class _SubjectSection extends StatelessWidget {
  final Subject subject;
  final DateTime date;
  final VoidCallback onAddTodo;
  final VoidCallback onAddSession;

  const _SubjectSection({
    required this.subject,
    required this.date,
    required this.onAddTodo,
    required this.onAddSession,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final todos = provider.todosForSubjectDay(subject.id, date);
    final sessions = provider.sessionsForDay(date)
        .where((s) => s.subjectId == subject.id)
        .toList();
    final color = Color(subject.colorValue);
    final hasItems = todos.isNotEmpty || sessions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
          child: Row(
            children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Text(subject.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (hasItems)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${todos.where((t) => t.isCompletedOn(date)).length + sessions.where((s) => s.isCompleted).length}/${todos.length + sessions.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              // Add todo
              _IconAction(
                icon: Icons.check_box_outline_blank_rounded,
                tooltip: '新增待辦',
                onTap: onAddTodo,
              ),
              const SizedBox(width: 4),
              // Add session
              _IconAction(
                icon: Icons.timer_outlined,
                tooltip: '新增讀書時段',
                onTap: onAddSession,
              ),
            ],
          ),
        ),

        // Todo items
        ...todos.map((t) => _TodoTile(todo: t, date: date, color: color)),

        // Study sessions
        ...sessions.map((s) => _SessionTile(session: s, color: color)),

        const Divider(height: 1, thickness: 0.6, indent: 20, endIndent: 20),
      ],
    );
  }
}

// ── Todo tile ─────────────────────────────────────────────────────────────────

class _TodoTile extends StatelessWidget {
  final TodoItem todo;
  final DateTime date;
  final Color color;

  const _TodoTile({
    required this.todo,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final done = todo.isCompletedOn(date);

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
          padding: const EdgeInsets.fromLTRB(36, 8, 20, 8),
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
                    // Weekday badges
                    const SizedBox(height: 3),
                    _WeekdayBadges(weekdays: todo.weekdays, color: color),
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
  final dynamic session;
  final Color color;
  const _SessionTile({required this.session, required this.color});

  @override
  Widget build(BuildContext context) {
    final done = session.isCompleted as bool;
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
          context.read<AppProvider>().deleteSession(session.id as String),
      child: InkWell(
        onTap: () => context.read<AppProvider>().toggleSession(session),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 8, 20, 8),
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
                    const Icon(Icons.timer_outlined, size: 14,
                        color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${formatHHMM(session.startHour as int, session.startMinute as int)}  ${formatDuration(session.durationMinutes as int)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: done ? Colors.grey.shade400 : Colors.black87,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if ((session.note as String).isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.note as String,
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
