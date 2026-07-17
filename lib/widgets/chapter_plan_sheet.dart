import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter_plan.dart';
import '../models/subject.dart';
import '../providers/app_provider.dart';

const _uuid = Uuid();
const _wdShort = ['一', '二', '三', '四', '五', '六', '日'];

/// Shows a bottom sheet to create or edit a ChapterPlan for [subject].
/// Pass [existing] when editing.
/// Pass [preselectedDay] (1-7) to pre-tick a weekday (e.g. from 讀書計劃).
void showChapterPlanSheet(
  BuildContext context,
  Subject subject, {
  ChapterPlan? existing,
  int? preselectedDay,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _ChapterPlanSheetBody(
      subject: subject,
      existing: existing,
      preselectedDay: preselectedDay,
    ),
  );
}

class _ChapterPlanSheetBody extends StatefulWidget {
  final Subject subject;
  final ChapterPlan? existing;
  final int? preselectedDay;

  const _ChapterPlanSheetBody({
    required this.subject,
    this.existing,
    this.preselectedDay,
  });

  @override
  State<_ChapterPlanSheetBody> createState() => _ChapterPlanSheetBodyState();
}

class _ChapterPlanSheetBodyState extends State<_ChapterPlanSheetBody> {
  late int _chapters;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    _chapters = widget.existing?.weeklyChapters ?? 5;
    if (widget.existing != null) {
      _days = {...widget.existing!.studyDays};
    } else if (widget.preselectedDay != null) {
      _days = {widget.preselectedDay!};
    } else {
      _days = {1, 3, 5};
    }
  }

  Color get _color => Color(widget.subject.colorValue);

  @override
  Widget build(BuildContext context) {
    final sortedDays = _days.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(backgroundColor: _color, radius: 9),
                const SizedBox(width: 10),
                Text(widget.subject.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('章節計畫',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Chapter / page count ─────────────────────────────────────
            Text('每週章節／頁數',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  color: _color,
                  enabled: _chapters > 1,
                  onTap: () => setState(() => _chapters--),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text('$_chapters',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _color)),
                    Text('課 / 頁',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(width: 20),
                _StepBtn(
                  icon: Icons.add,
                  color: _color,
                  enabled: true,
                  onTap: () => setState(() => _chapters++),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Study days ───────────────────────────────────────────────
            Text('讀書日',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final wd = i + 1;
                final active = _days.contains(wd);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (active) {
                        _days.remove(wd);
                      } else {
                        _days.add(wd);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? _color : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _wdShort[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
            const SizedBox(height: 16),

            // ── Distribution preview ─────────────────────────────────────
            if (sortedDays.isNotEmpty)
              _DistributionPreview(
                  chapters: _chapters,
                  days: sortedDays,
                  color: _color),

            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────────
            Row(
              children: [
                if (widget.existing != null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 16),
                    label: const Text('刪除計畫',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () {
                      context
                          .read<AppProvider>()
                          .deleteChapterPlan(widget.existing!.id);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _color,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _days.isEmpty
                        ? null
                        : () {
                            final plan = ChapterPlan(
                              id: widget.existing?.id ?? _uuid.v4(),
                              subjectId: widget.subject.id,
                              weeklyChapters: _chapters,
                              studyDays: sortedDays,
                              completedKeys:
                                  widget.existing?.completedKeys,
                            );
                            context
                                .read<AppProvider>()
                                .saveChapterPlan(plan);
                            Navigator.pop(context);
                          },
                    child: const Text('儲存',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Distribution preview ──────────────────────────────────────────────────────

class _DistributionPreview extends StatelessWidget {
  final int chapters;
  final List<int> days;
  final Color color;

  const _DistributionPreview({
    required this.chapters,
    required this.days,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = chapters ~/ days.length;
    final extra = chapters % days.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
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
            children: days.asMap().entries.map((e) {
              final dayChapters =
                  e.key < extra ? base + 1 : base;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '週${_wdShort[e.value - 1]}：$dayChapters課',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Step button ───────────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? color.withAlpha(25) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: enabled ? color.withAlpha(80) : Colors.grey.shade200),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}
