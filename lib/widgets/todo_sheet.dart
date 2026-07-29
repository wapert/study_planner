import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_item.dart';
import '../providers/app_provider.dart';

const _uuid = Uuid();
const _weekdayShort = ['一', '二', '三', '四', '五', '六', '日'];

/// Shows the add/edit sheet for a 待辦事項.
///
/// [date] is the day the sheet was opened from (used as the one-time date for
/// new todos). Pass [existing] to edit instead of create.
void showTodoSheet(
  BuildContext context, {
  required DateTime date,
  TodoItem? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _TodoSheetBody(date: date, existing: existing),
  );
}

class _TodoSheetBody extends StatefulWidget {
  final DateTime date;
  final TodoItem? existing;
  const _TodoSheetBody({required this.date, this.existing});

  @override
  State<_TodoSheetBody> createState() => _TodoSheetBodyState();
}

class _TodoSheetBodyState extends State<_TodoSheetBody> {
  late TextEditingController _titleCtrl;
  String? _subjectId;
  late bool _repeat;
  late Set<int> _weekdays;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _subjectId = e?.subjectId;
    // New todos default to NOT repeating (one-time on the selected date).
    _repeat = e?.isRepeating ?? false;
    _weekdays = {
      ...(e != null && e.isRepeating && e.weekdays.isNotEmpty
          ? e.weekdays
          : {widget.date.weekday})
    };
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.read<AppProvider>().subjects;
    final accent = _subjectId == null
        ? Colors.black
        : Color(subjects
            .firstWhere((s) => s.id == _subjectId,
                orElse: () => subjects.first)
            .colorValue);

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
            Row(
              children: [
                Text(_isEdit ? '編輯待辦事項' : '新增待辦事項',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 22),
                    tooltip: '刪除',
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: !_isEdit,
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
              const _Label('科目（選填）'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('無'),
                    selected: _subjectId == null,
                    onSelected: (_) => setState(() => _subjectId = null),
                  ),
                  ...subjects.map((s) => ChoiceChip(
                        avatar: CircleAvatar(
                            backgroundColor: Color(s.colorValue), radius: 6),
                        label: Text(s.name),
                        selected: _subjectId == s.id,
                        onSelected: (_) => setState(() => _subjectId = s.id),
                      )),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Repeat toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _repeat,
              activeThumbColor: accent,
              title: const Text('每週重複',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: Text(
                _repeat
                    ? '在選定的星期重複出現'
                    : '只出現在 ${widget.date.month}/${widget.date.day} 這一天',
                style: const TextStyle(fontSize: 12),
              ),
              onChanged: (v) => setState(() => _repeat = v),
            ),

            // Weekday chips (only when repeating)
            if (_repeat) ...[
              const SizedBox(height: 8),
              Row(
                children: List.generate(7, (i) {
                  final wd = i + 1; // 1=Mon
                  final active = _weekdays.contains(wd);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (active) {
                          _weekdays.remove(wd);
                        } else {
                          _weekdays.add(wd);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? accent : Colors.grey.shade100,
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
                onTap: () => setState(() {
                  if (_weekdays.length == 7) {
                    _weekdays = {widget.date.weekday};
                  } else {
                    _weekdays = {1, 2, 3, 4, 5, 6, 7};
                  }
                }),
                child: Row(
                  children: [
                    Icon(
                      _weekdays.length == 7
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
            ],
            const SizedBox(height: 20),

            // Save
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: Text(_isEdit ? '儲存' : '新增',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    // Repeating with no weekday picked → fall back to the opened day.
    List<int> weekdays = <int>[];
    if (_repeat) {
      final set = _weekdays.isEmpty ? {widget.date.weekday} : _weekdays;
      weekdays = set.toList()..sort();
    }
    final onDateKey =
        _repeat ? null : TodoItem.dateKeyOf(widget.date);

    final provider = context.read<AppProvider>();
    final existing = widget.existing;
    if (existing == null) {
      provider.addTodo(TodoItem(
        id: _uuid.v4(),
        title: title,
        subjectId: _subjectId,
        weekdays: weekdays,
        onDateKey: onDateKey,
      ));
    } else {
      existing.title = title;
      existing.subjectId = _subjectId;
      existing.weekdays = weekdays;
      existing.onDateKey = onDateKey;
      provider.updateTodo(existing);
    }
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final todo = widget.existing!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除待辦'),
        content: Text(todo.isRepeating
            ? '確定刪除「${todo.title}」？\n（所有星期的此項目都會刪除）'
            : '確定刪除「${todo.title}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AppProvider>().deleteTodo(todo.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600));
}
