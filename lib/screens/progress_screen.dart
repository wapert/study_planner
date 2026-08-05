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
  // Week navigation is transient UI state; the custom range lives in the
  // provider (persisted per-account) so it never leaks between users.
  DateTime _weekStart = DateTime.now().weekStart;

  bool _customOf(AppProvider p) =>
      p.progressUsesCustomRange &&
      p.progressCustomStart != null &&
      p.progressCustomEnd != null;

  (DateTime, DateTime) _rangeOf(AppProvider p) => _customOf(p)
      ? (p.progressCustomStart!.dateOnly, p.progressCustomEnd!.dateOnly)
      : (_weekStart.dateOnly, _weekStart.add(const Duration(days: 6)).dateOnly);

  bool _inRange(AppProvider p, DateTime d) {
    final (s, e) = _rangeOf(p);
    final x = d.dateOnly;
    return !x.isBefore(s) && !x.isAfter(e);
  }

  /// Label for the range selector. Only says 本週 when the shown week really
  /// is the current one; otherwise shows the actual dates.
  String _rangeLabel(
      AppProvider p, bool custom, DateTime rStart, DateTime rEnd) {
    if (custom) {
      final title = p.progressCustomTitle;
      return title.isNotEmpty ? title : '自訂';
    }
    if (_weekStart.dateOnly == DateTime.now().weekStart.dateOnly) {
      return '本週';
    }
    return '${rStart.month}/${rStart.day}–${rEnd.month}/${rEnd.day}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final custom = _customOf(provider);
    final (rStart, rEnd) = _rangeOf(provider);
    final days = rEnd.difference(rStart).inDays + 1;

    // Completed sessions in the selected range (with an existing subject).
    final completed = provider.sessions
        .where((s) =>
            s.isCompleted &&
            provider.subjectById(s.subjectId) != null &&
            _inRange(provider, s.date))
        .toList();
    final totalMin = completed.fold(0, (a, s) => a + s.durationMinutes);
    final perSubject = <String, int>{};
    for (final s in completed) {
      perSubject[s.subjectId] =
          (perSubject[s.subjectId] ?? 0) + s.durationMinutes;
    }

    // Subjects that actually have a planned time goal.
    final timedSubjects =
        provider.subjects.where((s) => s.weeklyGoalMinutes > 0).toList();

    // Chapter plans that will actually render a row: the subject still
    // exists, the period overlaps the range, AND at least one study day falls
    // inside it. Without the last two checks the 章節完成度 header could show
    // with nothing beneath it.
    final plans = provider.chapterPlans.where((p) {
      if (provider.subjectById(p.subjectId) == null) return false;
      if (!p.allStudyDates.any((d) => _inRange(provider, d))) return false;
      return true;
    }).where((p) {
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
            onPressed: custom
                ? null
                : () => setState(() =>
                    _weekStart = _weekStart.subtract(const Duration(days: 7))),
          ),
          PopupMenuButton<String>(
            tooltip: '選擇範圍',
            onSelected: (v) {
              if (v == 'week') {
                setState(() => _weekStart = DateTime.now().weekStart);
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
                      _rangeLabel(provider, custom, rStart, rEnd),
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
            onPressed: custom
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
                  if (custom && provider.progressCustomTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(provider.progressCustomTitle,
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
          // Only subjects with a planned weekly goal are listed.
          if (timedSubjects.isNotEmpty) ...[
            const Text('計劃時間完成度',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
          ],
          ...timedSubjects.map((s) {
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
              final studyDates = plan.allStudyDates
                  .where((d) => _inRange(provider, d))
                  .toList();
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
    final provider = context.read<AppProvider>();
    final wasCustom = _customOf(provider);
    DateTime start =
        wasCustom ? provider.progressCustomStart! : _weekStart;
    DateTime end = wasCustom
        ? provider.progressCustomEnd!
        : _weekStart.add(const Duration(days: 6));
    final titleCtrl =
        TextEditingController(text: provider.progressCustomTitle);

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

    if (ok == true && mounted) {
      // Saving notifies the provider, which rebuilds this screen.
      await context
          .read<AppProvider>()
          .saveProgressCustomRange(start, end, titleCtrl.text.trim());
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
