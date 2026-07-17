import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter_plan.dart';
import '../models/subject.dart';
import '../providers/app_provider.dart';

const _uuid = Uuid();
const _wdShort = ['一', '二', '三', '四', '五', '六', '日'];

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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _unitIndex = e?.unitIndex ?? 0;
    _startCtrl =
        TextEditingController(text: '${e?.startNum ?? 1}');
    _endCtrl =
        TextEditingController(text: '${e?.endNum ?? 10}');
    if (e != null) {
      _days = {...e.studyDays};
    } else if (widget.preselectedDay != null) {
      _days = {widget.preselectedDay!};
    } else {
      _days = {1, 3, 5};
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

  List<(int, int)> get _distribution {
    final sortedDays = _days.toList()..sort();
    if (sortedDays.isEmpty || _total <= 0) return [];
    final n = sortedDays.length;
    final base = _total ~/ n;
    final extra = _total % n;
    int cur = _start;
    final result = <(int, int)>[];
    for (int i = 0; i < n; i++) {
      final count = i < extra ? base + 1 : base;
      result.add((cur, cur + count - 1));
      cur += count;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sortedDays = _days.toList()..sort();
    final dist = _distribution;

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

            // ── Unit picker ─────────────────────────────────────────────
            _Label('單位'),
            const SizedBox(height: 8),
            Row(
              children: [
                _UnitChip(
                  label: '課',
                  selected: _unitIndex == 0,
                  color: _color,
                  onTap: () => setState(() => _unitIndex = 0),
                ),
                const SizedBox(width: 10),
                _UnitChip(
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
            _Label('讀書日'),
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? _color
                            : Colors.grey.shade100,
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
            if (sortedDays.isNotEmpty && dist.isNotEmpty && _total > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('每日分配',
                        style: TextStyle(
                            fontSize: 12,
                            color: _color,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(sortedDays.length, (i) {
                        final wd = sortedDays[i];
                        final r = dist[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _color.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '週${_wdShort[wd - 1]}：第${r.$1}～第${r.$2}$_unit',
                            style: TextStyle(
                                fontSize: 12,
                                color: _color,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
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
                    onPressed: (_days.isEmpty || _total <= 0)
                        ? null
                        : () {
                            final plan = ChapterPlan(
                              id: widget.existing?.id ?? _uuid.v4(),
                              subjectId: widget.subject.id,
                              startNum: _start,
                              endNum: _end,
                              unitIndex: _unitIndex,
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

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _UnitChip(
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
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black54,
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
