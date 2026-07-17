import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter_plan.dart';
import '../models/subject.dart';
import '../providers/app_provider.dart';
import '../utils/date_utils.dart';

const _uuid = Uuid();
const _weekdayShort = ['一', '二', '三', '四', '五', '六', '日'];

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
            onPressed: () => setState(
                () => _weekStart = _weekStart.subtract(const Duration(days: 7))),
          ),
          TextButton(
            onPressed: () =>
                setState(() => _weekStart = DateTime.now().weekStart),
            child: const Text('本週'),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(
                () => _weekStart = _weekStart.add(const Duration(days: 7))),
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
            final progress = provider.subjectGoalProgress(s.id, _weekStart);
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
                          style: const TextStyle(fontWeight: FontWeight.w500)),
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

          const SizedBox(height: 8),
          const Divider(height: 32),

          // ── Chapter plan section ────────────────────────────────────────
          Row(
            children: [
              const Text('章節計畫',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新增'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                onPressed: () => _showChapterPlanDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (chapterPlans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '尚無章節計畫，點擊「新增」為各科目設定每週章節目標',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ...chapterPlans.map((plan) {
              final subject = provider.subjectById(plan.subjectId);
              if (subject == null) return const SizedBox.shrink();
              return _ChapterCard(
                plan: plan,
                subject: subject,
                weekStart: _weekStart,
                onEdit: () => _showChapterPlanDialog(context, plan),
                onDelete: () => _confirmDeletePlan(context, plan),
                onToggleDay: (date) =>
                    provider.toggleChapterDay(plan, date),
              );
            }),

          // Quick-add chips for subjects without a plan
          () {
            final withPlan =
                chapterPlans.map((p) => p.subjectId).toSet();
            final without =
                subjects.where((s) => !withPlan.contains(s.id)).toList();
            if (without.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: without.map((s) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(s.colorValue),
                      radius: 8,
                    ),
                    label: Text('+ ${s.name}'),
                    labelStyle: const TextStyle(fontSize: 12),
                    onPressed: () => _showChapterPlanDialog(context, null,
                        preselectedSubject: s),
                  );
                }).toList(),
              ),
            );
          }(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Add / Edit chapter plan dialog ─────────────────────────────────────────

  void _showChapterPlanDialog(BuildContext context, ChapterPlan? existing,
      {Subject? preselectedSubject}) {
    final provider = context.read<AppProvider>();
    final subjects = provider.subjects;
    final withPlan = provider.chapterPlans.map((p) => p.subjectId).toSet();

    // Available subjects: existing is always included; new ones exclude subjects that already have plans
    final availableSubjects = existing != null
        ? subjects
        : subjects
            .where((s) =>
                !withPlan.contains(s.id) ||
                s.id == (preselectedSubject?.id ?? ''))
            .toList();

    if (availableSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有科目都已設定章節計畫')),
      );
      return;
    }

    Subject selectedSubject = preselectedSubject ??
        (existing != null
            ? subjects.firstWhere((s) => s.id == existing.subjectId,
                orElse: () => availableSubjects.first)
            : availableSubjects.first);

    int chapters = existing?.weeklyChapters ?? 3;
    final selectedDays = <int>{
      ...(existing?.studyDays ?? [1, 3, 5]),
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return AlertDialog(
            title: Text(existing == null ? '新增章節計畫' : '編輯章節計畫'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject picker (only when adding new)
                  if (existing == null) ...[
                    const Text('科目',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Subject>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: availableSubjects
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                        backgroundColor: Color(s.colorValue),
                                        radius: 6),
                                    const SizedBox(width: 8),
                                    Text(s.name),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (s) {
                        if (s != null) setModal(() => selectedSubject = s);
                      },
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Row(
                      children: [
                        CircleAvatar(
                            backgroundColor:
                                Color(selectedSubject.colorValue),
                            radius: 8),
                        const SizedBox(width: 8),
                        Text(selectedSubject.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Weekly chapter count
                  const Text('每週章節數（課/章）',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepBtn(
                        icon: Icons.remove,
                        onTap: chapters > 1
                            ? () => setModal(() => chapters--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('$chapters 課',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                      _StepBtn(
                        icon: Icons.add,
                        onTap: () => setModal(() => chapters++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Study days
                  const Text('讀書日',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(7, (i) {
                      final wd = i + 1;
                      final active = selectedDays.contains(wd);
                      final color = Color(selectedSubject.colorValue);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModal(() {
                            if (active) {
                              selectedDays.remove(wd);
                            } else {
                              selectedDays.add(wd);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? color : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _weekdayShort[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (selectedDays.isNotEmpty && chapters > 0) ...[
                    const SizedBox(height: 16),
                    _ChapterDistributionPreview(
                      chapters: chapters,
                      studyDays: selectedDays.toList()..sort(),
                      color: Color(selectedSubject.colorValue),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消')),
              FilledButton(
                onPressed: selectedDays.isEmpty
                    ? null
                    : () {
                        final plan = ChapterPlan(
                          id: existing?.id ?? _uuid.v4(),
                          subjectId: selectedSubject.id,
                          weeklyChapters: chapters,
                          studyDays: selectedDays.toList()..sort(),
                          completedKeys: existing?.completedKeys,
                        );
                        context.read<AppProvider>().saveChapterPlan(plan);
                        Navigator.pop(ctx);
                      },
                child: const Text('儲存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeletePlan(BuildContext context, ChapterPlan plan) {
    final subject = context.read<AppProvider>().subjectById(plan.subjectId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除章節計畫'),
        content: Text('確定要刪除「${subject?.name ?? ''}」的章節計畫？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AppProvider>().deleteChapterPlan(plan.id);
              Navigator.pop(ctx);
            },
            child: const Text('刪除'),
          ),
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

// ── Chapter plan card ─────────────────────────────────────────────────────────

class _ChapterCard extends StatelessWidget {
  final ChapterPlan plan;
  final Subject subject;
  final DateTime weekStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<DateTime> onToggleDay;

  const _ChapterCard({
    required this.plan,
    required this.subject,
    required this.weekStart,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final completed = provider.weeklyChaptersCompleted(plan, weekStart);
    final total = plan.weeklyChapters;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final color = Color(subject.colorValue);

    // Build list of study days in this week
    final studyDatesThisWeek = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (plan.isStudyDay(day)) {
        studyDatesThisWeek.add(day);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                    backgroundColor: color, radius: 7),
                const SizedBox(width: 10),
                Text(subject.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                Text(
                  '$completed / $total 課',
                  style: TextStyle(
                      fontSize: 13,
                      color: completed >= total
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: color.withAlpha(40),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),

            // Day chips
            if (studyDatesThisWeek.isEmpty)
              Text('本週無排定讀書日',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: studyDatesThisWeek.map((day) {
                  final chapCount = plan.chaptersForDate(day);
                  final done = plan.isCompletedOn(day);
                  return GestureDetector(
                    onTap: () => onToggleDay(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            done ? color : color.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: done
                              ? color
                              : color.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (done)
                            const Icon(Icons.check,
                                size: 13, color: Colors.white)
                          else
                            Icon(Icons.menu_book_outlined,
                                size: 13, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '週${_weekdayShort[day.weekday - 1]}  $chapCount課',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  done ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Distribution preview (inside dialog) ─────────────────────────────────────

class _ChapterDistributionPreview extends StatelessWidget {
  final int chapters;
  final List<int> studyDays;
  final Color color;

  const _ChapterDistributionPreview({
    required this.chapters,
    required this.studyDays,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (studyDays.isEmpty) return const SizedBox.shrink();
    final base = chapters ~/ studyDays.length;
    final extra = chapters % studyDays.length;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('每日分配',
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: studyDays.asMap().entries.map((entry) {
              final i = entry.key;
              final wd = entry.value;
              final dayChapters = i < extra ? base + 1 : base;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '週${_weekdayShort[wd - 1]}: $dayChapters課',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Step button helper ────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.grey.shade200
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap != null
                ? Colors.black87
                : Colors.grey.shade400),
      ),
    );
  }
}
