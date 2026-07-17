import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/date_utils.dart';

const _wdShort = ['一', '二', '三', '四', '五', '六', '日'];

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  DateTime _weekStart = DateTime.now().weekStart;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final totalMin = provider.totalMinutesThisWeek(_weekStart);
    final perSubject = provider.weeklyMinutesPerSubject(_weekStart);
    final subjects = provider.subjects;
    final chapterPlans = provider.chapterPlans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('進度追蹤'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() =>
                _weekStart = _weekStart.subtract(const Duration(days: 7))),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WeekSummaryCard(totalMin: totalMin, weekStart: _weekStart),
          const SizedBox(height: 16),
          if (perSubject.isNotEmpty) ...[
            _PieChartCard(perSubject: perSubject, subjects: subjects),
            const SizedBox(height: 16),
          ],

          // ── Time goal progress ──────────────────────────────────────────
          const Text('各科目時間完成度',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...subjects.map((s) {
            final progress =
                provider.subjectGoalProgress(s.id, _weekStart);
            final done = perSubject[s.id] ?? 0;
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
                      Text(s.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(
                        '${formatDuration(done)} / ${formatDuration(s.weeklyGoalMinutes)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                          Color(s.colorValue).withAlpha(40),
                      valueColor: AlwaysStoppedAnimation(
                          Color(s.colorValue)),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Chapter progress (stats only) ───────────────────────────────
          if (chapterPlans.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('章節完成度',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('在「科目」頁可設定或修改章節計畫',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            ...chapterPlans.map((plan) {
              final subject = provider.subjectById(plan.subjectId);
              if (subject == null) return const SizedBox.shrink();
              final completed =
                  provider.weeklyChaptersCompleted(plan, _weekStart);
              final total = plan.totalCount;
              final progress =
                  total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
              final color = Color(subject.colorValue);

              // Study days in this week
              final studyDates = <DateTime>[];
              for (int i = 0; i < 7; i++) {
                final d = _weekStart.add(Duration(days: i));
                if (plan.isStudyDay(d)) studyDates.add(d);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                            backgroundColor: color, radius: 7),
                        const SizedBox(width: 8),
                        Text(subject.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              plan.fullRangeLabel,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                            ),
                            Text(
                              '$completed / $total${plan.unitLabel}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: completed >= total
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
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
                        valueColor:
                            AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: studyDates.map((day) {
                        final done = plan.isCompletedOn(day);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: done
                                ? color
                                : color.withAlpha(20),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: done
                                    ? color
                                    : color.withAlpha(70)),
                          ),
                          child: Text(
                            '週${_wdShort[day.weekday - 1]} ${plan.rangeLabelForDate(day)}${done ? ' ✓' : ''}',
                            style: TextStyle(
                                fontSize: 12,
                                color: done
                                    ? Colors.white
                                    : color,
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
}

// ── Week summary card ─────────────────────────────────────────────────────────

class _WeekSummaryCard extends StatelessWidget {
  final int totalMin;
  final DateTime weekStart;
  const _WeekSummaryCard(
      {required this.totalMin, required this.weekStart});

  @override
  Widget build(BuildContext context) {
    final end = weekStart.add(const Duration(days: 6));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${weekStart.month}/${weekStart.day} – ${end.month}/${end.day}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              formatDuration(totalMin),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const Text('本週完成讀書時數'),
          ],
        ),
      ),
    );
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
      final subject = subjects.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => null,
      );
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
