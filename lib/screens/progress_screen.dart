import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/account_button.dart';

const _blue = Color(0xFF1E88E5);

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _custom = false;
  DateTime _weekStart = DateTime.now().weekStart;
  DateTime _customStart = DateTime.now().weekStart;
  DateTime _customEnd = DateTime.now().weekStart.add(const Duration(days: 6));
  String _customTitle = '';

  @override
  void initState() {
    super.initState();
    // Restore the last-selected range so it survives navigation, app
    // restarts, and sign-out/sign-in (persisted locally on-device).
    final provider = context.read<AppProvider>();
    if (provider.progressUsesCustomRange) {
      final start = provider.progressCustomStart;
      final end = provider.progressCustomEnd;
      if (start != null && end != null) {
        _custom = true;
        _customStart = start;
        _customEnd = end;
        _customTitle = provider.progressCustomTitle;
      }
    }
  }

  (DateTime, DateTime) get _range => _custom
      ? (_customStart.dateOnly, _customEnd.dateOnly)
      : (_weekStart.dateOnly, _weekStart.add(const Duration(days: 6)).dateOnly);

  bool _inRange(DateTime d) {
    final (s, e) = _range;
    final x = d.dateOnly;
    return !x.isBefore(s) && !x.isAfter(e);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final (rStart, rEnd) = _range;
    final days = rEnd.difference(rStart).inDays + 1;

    // Completed sessions in the selected range (with an existing subject).
    final completed = provider.sessions
        .where((s) =>
            s.isCompleted &&
            provider.subjectById(s.subjectId) != null &&
            _inRange(s.date))
        .toList();
    final totalMin = completed.fold(0, (a, s) => a + s.durationMinutes);
    final perSubject = <String, int>{};
    for (final s in completed) {
      perSubject[s.subjectId] =
          (perSubject[s.subjectId] ?? 0) + s.durationMinutes;
    }

    // Chapter plans whose period overlaps the selected range.
    final plans = provider.chapterPlans.where((p) {
      final ps = p.startDate.dateOnly;
      final pe = p.endDate.dateOnly;
      return !pe.isBefore(rStart) && !ps.isAfter(rEnd);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('進度追蹤'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _custom
                ? null
                : () => setState(() =>
                    _weekStart = _weekStart.subtract(const Duration(days: 7))),
          ),
          PopupMenuButton<String>(
            tooltip: '選擇範圍',
            onSelected: (v) {
              if (v == 'week') {
                setState(() {
                  _custom = false;
                  _weekStart = DateTime.now().weekStart;
                });
                context.read<AppProvider>().saveProgressWeekMode();
              } else if (v == 'custom') {
                _pickCustom();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'week', child: Text('本週')),
              PopupMenuItem(value: 'custom', child: Text('自訂範圍…')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _custom
                          ? (_customTitle.isNotEmpty ? _customTitle : '自訂')
                          : '本週',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _custom
                ? null
                : () => setState(() =>
                    _weekStart = _weekStart.add(const Duration(days: 7))),
          ),
          const AccountButton(),
          PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (v) {
              if (v == 'reset') _resetProgress(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 20),
                    SizedBox(width: 10),
                    Text('重設進度'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary card ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_custom && _customTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(_customTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  Text(
                    '${rStart.month}/${rStart.day} – ${rEnd.month}/${rEnd.day}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDuration(totalMin),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                            fontWeight: FontWeight.bold, color: _blue),
                  ),
                  const Text('此範圍完成讀書時數'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (perSubject.isNotEmpty) ...[
            _PieChartCard(perSubject: perSubject, subjects: provider.subjects),
            const SizedBox(height: 16),
          ],

          // ── Per-subject time completion ─────────────────────────────────
          const Text('各科目時間完成度',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...provider.subjects.map((s) {
            final done = perSubject[s.id] ?? 0;
            // Goal is weekly; scale it to the range length.
            final goal = (s.weeklyGoalMinutes * days / 7).round();
            final progress =
                goal > 0 ? (done / goal).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: Color(s.colorValue),
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatDuration(done)} / ${formatDuration(goal)}',
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

          // ── Chapter completion (range-scoped) ───────────────────────────
          if (plans.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('章節完成度',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...plans.map((plan) {
              final subject = provider.subjectById(plan.subjectId);
              if (subject == null) return const SizedBox.shrink();

              // Study dates of this plan that fall inside the selected range.
              final studyDates =
                  plan.allStudyDates.where(_inRange).toList();
              if (studyDates.isEmpty) return const SizedBox.shrink();

              int assigned = 0;
              int done = 0;
              for (final d in studyDates) {
                final c = plan.chaptersForDate(d);
                assigned += c;
                if (plan.isCompletedOn(d)) done += c;
              }
              final progress =
                  assigned > 0 ? (done / assigned).clamp(0.0, 1.0) : 0.0;
              final color = Color(subject.colorValue);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: color, radius: 7),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              '${plan.versionPrefix}${subject.name}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          '$done / $assigned${plan.unitLabel}',
                          style: TextStyle(
                              fontSize: 13,
                              color: done >= assigned
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: studyDates.map((day) {
                        final isDone = plan.isCompletedOn(day);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDone ? color : color.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isDone
                                    ? color
                                    : color.withAlpha(70)),
                          ),
                          child: Text(
                            '${day.month}/${day.day} ${plan.rangeLabelForDate(day)}${isDone ? ' ✓' : ''}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDone ? Colors.white : color,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Custom range picker ─────────────────────────────────────────────────

  Future<void> _pickCustom() async {
    DateTime start = _custom ? _customStart : _weekStart;
    DateTime end =
        _custom ? _customEnd : _weekStart.add(const Duration(days: 6));
    final titleCtrl = TextEditingController(text: _customTitle);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('自訂範圍'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: '標題（選填）', hintText: '例如：期中考複習'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: start,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2028),
                        );
                        if (d != null) {
                          setDialog(() {
                            start = d;
                            if (end.isBefore(start)) end = start;
                          });
                        }
                      },
                      child: Text(
                          '起 ${start.year}/${start.month}/${start.day}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: end,
                          firstDate: start,
                          lastDate: DateTime(2028),
                        );
                        if (d != null) setDialog(() => end = d);
                      },
                      child:
                          Text('止 ${end.year}/${end.month}/${end.day}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('確定')),
          ],
        ),
      ),
    );

    if (ok == true) {
      final title = titleCtrl.text.trim();
      setState(() {
        _custom = true;
        _customStart = start;
        _customEnd = end;
        _customTitle = title;
      });
      if (mounted) {
        context.read<AppProvider>().saveProgressCustomRange(start, end, title);
      }
    }
  }

  Future<void> _resetProgress(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重設進度'),
        content: const Text(
            '將清除所有讀書時段的完成狀態與章節完成紀錄，進度歸零。\n（科目、章節計畫與時段本身會保留）\n確定要重設嗎？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('重設'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppProvider>().resetProgress();
    }
  }
}

// ── Pie chart card ────────────────────────────────────────────────────────────

class _PieChartCard extends StatelessWidget {
  final Map<String, int> perSubject;
  final List subjects;
  const _PieChartCard(
      {required this.perSubject, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final total = perSubject.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = perSubject.entries.map((entry) {
      dynamic subject;
      for (final s in subjects) {
        if (s.id == entry.key) {
          subject = s;
          break;
        }
      }
      if (subject == null) return null;
      final pct = entry.value / total * 100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: Color(subject.colorValue),
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).whereType<PieChartSectionData>().toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('科目分佈',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: PieChart(PieChartData(
                  sections: sections, sectionsSpace: 2)),
            ),
          ],
        ),
      ),
    );
  }
}
