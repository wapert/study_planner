import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter_plan.dart';
import '../models/subject.dart';
import '../providers/app_provider.dart';

const _uuid = Uuid();
const _wdShort = ['一', '二', '三', '四', '五', '六', '日'];

enum _PeriodMode { week, month, custom }

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
    builder: (ctx) => _SheetBody(
      subject: subject,
      existing: existing,
      preselectedDay: preselectedDay,
    ),
  );
}

class _SheetBody extends StatefulWidget {
  final Subject subject;
  final ChapterPlan? existing;
  final int? preselectedDay;
  const _SheetBody(
      {required this.subject, this.existing, this.preselectedDay});

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  late int _unitIndex; // 0=課 1=頁
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late Set<int> _days;
  late _PeriodMode _mode;
  late DateTime _customStart;
  late DateTime _customEnd;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _unitIndex = e?.unitIndex ?? 0;
    _startCtrl = TextEditingController(text: '${e?.startNum ?? 1}');
    _endCtrl = TextEditingController(text: '${e?.endNum ?? 10}');
    if (e != null) {
      _days = {...e.studyDays};
    } else if (widget.preselectedDay != null) {
      _days = {widget.preselectedDay!};
    } else {
      _days = {1, 3, 5};
    }

    // Detect period mode from existing plan
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    if (e == null) {
      _mode = _PeriodMode.week;
      _customStart = weekStart;
      _customEnd = weekEnd;
    } else {
      _customStart = e.startDate;
      _customEnd = e.endDate;
      if (e.startDateKey == ChapterPlan.dateKeyOf(weekStart) &&
          e.endDateKey == ChapterPlan.dateKeyOf(weekEnd)) {
        _mode = _PeriodMode.week;
      } else if (e.startDateKey == ChapterPlan.dateKeyOf(monthStart) &&
          e.endDateKey == ChapterPlan.dateKeyOf(monthEnd)) {
        _mode = _PeriodMode.month;
      } else {
        _mode = _PeriodMode.custom;
      }
    }
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Color get _color => Color(widget.subject.colorValue);

  int get _start => int.tryParse(_startCtrl.text) ?? 1;
  int get _end => int.tryParse(_endCtrl.text) ?? 1;
  int get _total => (_end - _start + 1).clamp(0, 99999);
  String get _unit => _unitIndex == 0 ? '課' : '頁';

  (DateTime, DateTime) get _period {
    final now = DateTime.now();
    switch (_mode) {
      case _PeriodMode.week:
        final ws = now.subtract(Duration(days: now.weekday - 1));
        return (ws, ws.add(const Duration(days: 6)));
      case _PeriodMode.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0)
        );
      case _PeriodMode.custom:
        return (_customStart, _customEnd);
    }
  }

  /// All concrete study dates in the selected period.
  List<DateTime> get _studyDates {
    final (pStart, pEnd) = _period;
    final result = <DateTime>[];
    var d = DateTime(pStart.year, pStart.month, pStart.day);
    final end = DateTime(pEnd.year, pEnd.month, pEnd.day);
    while (!d.isAfter(end)) {
      if (_days.contains(d.weekday)) result.add(d);
      d = d.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final (pStart, pEnd) = _period;
    final dates = _studyDates;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
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
            const SizedBox(height: 20),

            // ── Time period ────────────────────────────────────────────
            _Label('時間範圍'),
            const SizedBox(height: 8),
            Row(
              children: [
                _ModeChip(
                  label: '本週',
                  selected: _mode == _PeriodMode.week,
                  color: _color,
                  onTap: () =>
                      setState(() => _mode = _PeriodMode.week),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: '本月',
                  selected: _mode == _PeriodMode.month,
                  color: _color,
                  onTap: () =>
                      setState(() => _mode = _PeriodMode.month),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: '自訂',
                  selected: _mode == _PeriodMode.custom,
                  color: _color,
                  onTap: () =>
                      setState(() => _mode = _PeriodMode.custom),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_mode == _PeriodMode.custom)
              Row(
                children: [
                  _DateButton(
                    label:
                        '${_customStart.year}/${_customStart.month}/${_customStart.day}',
                    color: _color,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _customStart,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2028),
                      );
                      if (d != null) {
                        setState(() {
                          _customStart = d;
                          if (_customEnd.isBefore(d)) _customEnd = d;
                        });
                      }
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('～',
                        style: TextStyle(
                            color: Colors.grey.shade400)),
                  ),
                  _DateButton(
                    label:
                        '${_customEnd.year}/${_customEnd.month}/${_customEnd.day}',
                    color: _color,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _customEnd,
                        firstDate: _customStart,
                        lastDate: DateTime(2028),
                      );
                      if (d != null) {
                        setState(() => _customEnd = d);
                      }
                    },
                  ),
                ],
              )
            else
              Text(
                '${pStart.month}/${pStart.day} ～ ${pEnd.month}/${pEnd.day}',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            const SizedBox(height: 20),

            // ── Unit picker ─────────────────────────────────────────────
            _Label('單位'),
            const SizedBox(height: 8),
            Row(
              children: [
                _ModeChip(
                  label: '課',
                  selected: _unitIndex == 0,
                  color: _color,
                  onTap: () => setState(() => _unitIndex = 0),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: '頁',
                  selected: _unitIndex == 1,
                  color: _color,
                  onTap: () => setState(() => _unitIndex = 1),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Range inputs ─────────────────────────────────────────────
            _Label('範圍'),
            const SizedBox(height: 10),
            Row(
              children: [
                _NumField(
                  label: '第',
                  suffix: _unit,
                  hint: '起',
                  controller: _startCtrl,
                  color: _color,
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('～',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w300)),
                ),
                _NumField(
                  label: '第',
                  suffix: _unit,
                  hint: '止',
                  controller: _endCtrl,
                  color: _color,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '共 $_total $_unit',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            const SizedBox(height: 20),

            // ── Study days ──────────────────────────────────────────────
            _Label('讀書日（每週）'),
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
                      margin:
                          const EdgeInsets.symmetric(horizontal: 2),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            active ? _color : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _wdShort[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
            const SizedBox(height: 16),

            // ── Distribution preview ────────────────────────────────────
            if (dates.isNotEmpty && _total > 0)
              _DistributionPreview(
                startNum: _start,
                total: _total,
                unit: _unit,
                dates: dates,
                color: _color,
              ),

            const SizedBox(height: 24),

            // ── Actions ─────────────────────────────────────────────────
            Row(
              children: [
                if (widget.existing != null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 16),
                    label: const Text('刪除',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
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
                    onPressed: (_days.isEmpty ||
                            _total <= 0 ||
                            dates.isEmpty)
                        ? null
                        : () {
                            final (pS, pE) = _period;
                            final plan = ChapterPlan(
                              id: widget.existing?.id ?? _uuid.v4(),
                              subjectId: widget.subject.id,
                              startNum: _start,
                              endNum: _end,
                              unitIndex: _unitIndex,
                              studyDays: _days.toList()..sort(),
                              startDateKey:
                                  ChapterPlan.dateKeyOf(pS),
                              endDateKey: ChapterPlan.dateKeyOf(pE),
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
  final int startNum;
  final int total;
  final String unit;
  final List<DateTime> dates;
  final Color color;

  const _DistributionPreview({
    required this.startNum,
    required this.total,
    required this.unit,
    required this.dates,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final n = dates.length;
    final base = total ~/ n;
    final extra = total % n;

    // Build per-date labels; cap visible chips to keep the sheet compact.
    const maxChips = 10;
    final chips = <String>[];
    int cur = startNum;
    for (int i = 0; i < n && i < maxChips; i++) {
      final count = i < extra ? base + 1 : base;
      final d = dates[i];
      if (count <= 0) {
        chips.add('${d.month}/${d.day}：—');
      } else if (count == 1) {
        chips.add('${d.month}/${d.day}：第$cur$unit');
      } else {
        chips.add('${d.month}/${d.day}：第$cur~${cur + count - 1}$unit');
      }
      cur += count;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('每日分配（共 $n 個讀書日）',
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...chips.map((label) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600),
                    ),
                  )),
              if (n > maxChips)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('…還有 ${n - maxChips} 天',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey.shade700));
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ModeChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final String suffix;
  final String hint;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;

  const _NumField({
    required this.label,
    required this.suffix,
    required this.hint,
    required this.controller,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: Colors.grey.shade300, fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onChanged,
              ),
            ),
            Text(suffix,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
