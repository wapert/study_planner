import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/calendar_event.dart';
import '../models/chapter_plan.dart';
import '../services/share_service.dart';
import '../services/firestore_serializers.dart';
import '../utils/date_utils.dart';

const _blue = Color(0xFF1E88E5);
const _weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];

/// Read-only view of another user's plan across three tabs:
/// 進度 (Progress) · 讀書計畫 (Plan) · 行事曆 (Calendar).
class SharedPlanScreen extends StatefulWidget {
  final OwnerEntry owner;
  final ShareService share;
  const SharedPlanScreen(
      {super.key, required this.owner, required this.share});

  @override
  State<SharedPlanScreen> createState() => _SharedPlanScreenState();
}

class _SharedPlanScreenState extends State<SharedPlanScreen> {
  late Future<Map<String, List<dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.share.loadOwnerData(widget.owner.ownerUid);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.owner.ownerEmail),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: '進度'),
              Tab(text: '讀書計畫'),
              Tab(text: '行事曆'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, List<dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('無法載入：${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              );
            }
            final data = snap.data!;
            final subjects =
                (data[Collections.subjects] ?? []).cast<Subject>();
            final sessions =
                (data[Collections.sessions] ?? []).cast<StudySession>();
            final events =
                (data[Collections.events] ?? []).cast<CalendarEvent>();
            final plans =
                (data[Collections.chapterPlans] ?? []).cast<ChapterPlan>();

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: _blue.withAlpha(18),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility_outlined,
                          size: 14, color: _blue),
                      const SizedBox(width: 6),
                      Text('唯讀檢視',
                          style: TextStyle(
                              fontSize: 12,
                              color: _blue,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ProgressTab(
                          subjects: subjects,
                          sessions: sessions,
                          plans: plans),
                      _PlanTab(
                          subjects: subjects,
                          sessions: sessions,
                          plans: plans),
                      _CalendarTab(
                          subjects: subjects,
                          sessions: sessions,
                          events: events,
                          plans: plans),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Shared data helpers ───────────────────────────────────────────────────────

List<StudySession> _sessionsForDay(
    List<StudySession> all, List<Subject> subjects, DateTime day) {
  final d = day.dateOnly;
  return all
      .where((s) =>
          s.date.dateOnly.isSameDay(d) &&
          _subjectById(subjects, s.subjectId) != null)
      .toList()
    ..sort((a, b) => a.startHour != b.startHour
        ? a.startHour.compareTo(b.startHour)
        : a.startMinute.compareTo(b.startMinute));
}

List<CalendarEvent> _eventsForDay(List<CalendarEvent> all, DateTime day) {
  final d = day.dateOnly;
  return all.where((e) => e.date.dateOnly.isSameDay(d)).toList();
}

Subject? _subjectById(List<Subject> subjects, String id) {
  for (final s in subjects) {
    if (s.id == id) return s;
  }
  return null;
}

// ── Progress tab ──────────────────────────────────────────────────────────────

class _ProgressTab extends StatefulWidget {
  final List<Subject> subjects;
  final List<StudySession> sessions;
  final List<ChapterPlan> plans;
  const _ProgressTab(
      {required this.subjects, required this.sessions, required this.plans});

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  DateTime _weekStart = DateTime.now().weekStart;

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final weekSessions = widget.sessions.where((s) {
      final d = s.date.dateOnly;
      return s.isCompleted &&
          !d.isBefore(_weekStart) &&
          !d.isAfter(weekEnd);
    }).toList();
    final totalMin =
        weekSessions.fold(0, (sum, s) => sum + s.durationMinutes);
    final perSubject = <String, int>{};
    for (final s in weekSessions) {
      perSubject[s.subjectId] =
          (perSubject[s.subjectId] ?? 0) + s.durationMinutes;
    }
    final activePlans = widget.plans.where((p) => !p.isExpired).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WeekNav(
          weekStart: _weekStart,
          onPrev: () => setState(() =>
              _weekStart = _weekStart.subtract(const Duration(days: 7))),
          onNext: () => setState(() =>
              _weekStart = _weekStart.add(const Duration(days: 7))),
          onThisWeek: () =>
              setState(() => _weekStart = DateTime.now().weekStart),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDuration(totalMin),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                            fontWeight: FontWeight.bold, color: _blue)),
                const Text('本週完成讀書時數'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('各科目時間完成度',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...widget.subjects.map((s) {
          final done = perSubject[s.id] ?? 0;
          final progress = s.weeklyGoalMinutes > 0
              ? (done / s.weeklyGoalMinutes).clamp(0.0, 1.0)
              : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        backgroundColor: Color(s.colorValue), radius: 6),
                    const SizedBox(width: 8),
                    Text(s.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      '${formatDuration(done)} / ${formatDuration(s.weeklyGoalMinutes)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Color(s.colorValue).withAlpha(40),
                    valueColor:
                        AlwaysStoppedAnimation(Color(s.colorValue)),
                  ),
                ),
              ],
            ),
          );
        }),
        if (activePlans.isNotEmpty) ...[
          const Divider(height: 32),
          const Text('章節完成度',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...activePlans.map((plan) {
            final subject = _subjectById(widget.subjects, plan.subjectId);
            if (subject == null) return const SizedBox.shrink();
            int completed = 0;
            for (int i = 0; i < 7; i++) {
              final day = _weekStart.add(Duration(days: i));
              if (plan.activeOn(day) && plan.isCompletedOn(day)) {
                completed += plan.chaptersForDate(day);
              }
            }
            final total = plan.totalCount;
            final progress =
                total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
            final color = Color(subject.colorValue);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: color, radius: 6),
                      const SizedBox(width: 8),
                      Text('${plan.versionPrefix}${subject.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('$completed / $total${plan.unitLabel}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: color.withAlpha(40),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Plan tab ──────────────────────────────────────────────────────────────────

class _PlanTab extends StatefulWidget {
  final List<Subject> subjects;
  final List<StudySession> sessions;
  final List<ChapterPlan> plans;
  const _PlanTab(
      {required this.subjects, required this.sessions, required this.plans});

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  DateTime _weekStart = DateTime.now().weekStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _WeekNav(
            weekStart: _weekStart,
            onPrev: () => setState(() =>
                _weekStart = _weekStart.subtract(const Duration(days: 7))),
            onNext: () => setState(() =>
                _weekStart = _weekStart.add(const Duration(days: 7))),
            onThisWeek: () =>
                setState(() => _weekStart = DateTime.now().weekStart),
          ),
        ),
        ...List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final isToday = day.dateOnly.isSameDay(DateTime.now().dateOnly);
          final daySessions =
              _sessionsForDay(widget.sessions, widget.subjects, day);
          final dayPlans = widget.plans
              .where((p) => p.activeOn(day))
              .map((p) => (p, _subjectById(widget.subjects, p.subjectId)))
              .where((pair) => pair.$2 != null)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: isToday ? _blue.withAlpha(20) : null,
                child: Text(
                  '${_weekdayLabels[day.weekday % 7]}  ${day.month}/${day.day}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? _blue : null),
                ),
              ),
              if (dayPlans.isEmpty && daySessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text('無安排',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ),
              ...dayPlans.map((pair) {
                final plan = pair.$1;
                final subject = pair.$2!;
                final color = Color(subject.colorValue);
                final done = plan.isCompletedOn(day);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 34,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.menu_book_outlined,
                          size: 15,
                          color: done ? Colors.grey : color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${subject.name}  ·  ${plan.versionPrefix}${plan.rangeLabelForDate(day)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: done
                                ? Colors.grey
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (done)
                        const Icon(Icons.check_circle,
                            size: 18, color: Colors.green),
                    ],
                  ),
                );
              }),
              ...daySessions.map((s) {
                final subject =
                    _subjectById(widget.subjects, s.subjectId);
                final color =
                    subject != null ? Color(subject.colorValue) : Colors.grey;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 34,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${subject?.name ?? ''}  ${formatHHMM(s.startHour, s.startMinute)}  ${formatDuration(s.durationMinutes)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: s.isCompleted
                                ? Colors.grey
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                            decoration: s.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 1),
            ],
          );
        }),
      ],
    );
  }
}

// ── Calendar tab ──────────────────────────────────────────────────────────────

class _CalendarTab extends StatefulWidget {
  final List<Subject> subjects;
  final List<StudySession> sessions;
  final List<CalendarEvent> events;
  final List<ChapterPlan> plans;
  const _CalendarTab(
      {required this.subjects,
      required this.sessions,
      required this.events,
      required this.plans});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now().dateOnly;

  List<dynamic> _markersFor(DateTime day) => [
        ..._sessionsForDay(widget.sessions, widget.subjects, day),
        ..._eventsForDay(widget.events, day),
        ...widget.plans.where((p) => p.activeOn(day)),
      ];

  @override
  Widget build(BuildContext context) {
    final events = _eventsForDay(widget.events, _selected);
    final sessions =
        _sessionsForDay(widget.sessions, widget.subjects, _selected);
    final dayPlans = widget.plans
        .where((p) => p.activeOn(_selected))
        .map((p) => (p, _subjectById(widget.subjects, p.subjectId)))
        .where((pair) => pair.$2 != null)
        .toList();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2027, 12, 31),
          focusedDay: _focused,
          selectedDayPredicate: (d) => d.isSameDay(_selected),
          onDaySelected: (selected, focused) => setState(() {
            _selected = selected.dateOnly;
            _focused = focused;
          }),
          onPageChanged: (focused) => setState(() => _focused = focused),
          calendarFormat: CalendarFormat.month,
          eventLoader: _markersFor,
          calendarStyle: CalendarStyle(
            markerDecoration:
                const BoxDecoration(color: _blue, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(
                color: _blue.withAlpha(80), shape: BoxShape.circle),
            selectedDecoration:
                const BoxDecoration(color: _blue, shape: BoxShape.circle),
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
              if (dayPlans.isNotEmpty) ...[
                const Text('章節計畫',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...dayPlans.map((pair) {
                  final plan = pair.$1;
                  final subject = pair.$2!;
                  final color = Color(subject.colorValue);
                  final done = plan.isCompletedOn(_selected);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: color.withAlpha(22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.withAlpha(70)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                          backgroundColor: color, radius: 6),
                      title: Text(
                        '${subject.name}  ·  ${plan.versionPrefix}${plan.rangeLabelForDate(_selected)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: done ? Colors.grey : color,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: done
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 18)
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (events.isNotEmpty) ...[
                const Text('活動',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: events.map((e) {
                    final c = Color(e.type.colorValue);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.withAlpha(80)),
                      ),
                      child: Text('${e.type.label}· ${e.title}',
                          style: TextStyle(
                              fontSize: 12,
                              color: c,
                              fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (sessions.isNotEmpty) ...[
                const Text('讀書時段',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...sessions.map((s) {
                  final subject =
                      _subjectById(widget.subjects, s.subjectId);
                  final color = subject != null
                      ? Color(subject.colorValue)
                      : Colors.grey;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2))),
                    title: Text(subject?.name ?? '已刪除科目'),
                    subtitle: Text(
                        '${formatHHMM(s.startHour, s.startMinute)}  ${formatDuration(s.durationMinutes)}'),
                  );
                }),
              ],
              if (dayPlans.isEmpty &&
                  events.isEmpty &&
                  sessions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text('這天沒有安排',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Week navigation bar ───────────────────────────────────────────────────────

class _WeekNav extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;
  const _WeekNav({
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
    required this.onThisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final end = weekStart.add(const Duration(days: 6));
    return Row(
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Expanded(
          child: Center(
            child: TextButton(
              onPressed: onThisWeek,
              child: Text(
                '${weekStart.month}/${weekStart.day} – ${end.month}/${end.day}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ],
    );
  }
}
