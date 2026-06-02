import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/subject.dart';

const _uuid = Uuid();

const _palette = [
  0xFFE53935, 0xFF1E88E5, 0xFF43A047, 0xFF8E24AA,
  0xFFFF8F00, 0xFF00ACC1, 0xFF6D4C41, 0xFF546E7A,
  0xFFEC407A, 0xFF26A69A,
];

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<AppProvider>().subjects;

    return Scaffold(
      appBar: AppBar(title: const Text('科目管理'), centerTitle: false),
      body: subjects.isEmpty
          ? const Center(child: Text('尚無科目，請新增'))
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, i) {
                final s = subjects[i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Color(s.colorValue), radius: 14),
                  title: Text(s.name),
                  subtitle: Text('每週目標：${s.weeklyGoalMinutes ~/ 60} 小時 ${s.weeklyGoalMinutes % 60} 分鐘'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showSubjectDialog(context, subject: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, s),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新增科目'),
      ),
    );
  }

  void _showSubjectDialog(BuildContext context, {Subject? subject}) {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    int selectedColor = subject?.colorValue ?? _palette.first;
    int goalHours = subject != null ? subject.weeklyGoalMinutes ~/ 60 : 2;
    int goalMinutes = subject != null ? subject.weeklyGoalMinutes % 60 : 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(subject == null ? '新增科目' : '編輯科目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '科目名稱'),
                  autofocus: subject == null,
                ),
                const SizedBox(height: 16),
                const Text('顏色'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _palette.map((c) => GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: selectedColor == c
                            ? Border.all(width: 3, color: Colors.white)
                            : null,
                        boxShadow: selectedColor == c
                            ? [BoxShadow(color: Color(c).withAlpha(120), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('每週目標'),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: goalHours,
                        decoration: const InputDecoration(labelText: '小時'),
                        items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                        onChanged: (v) => setState(() => goalHours = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: goalMinutes,
                        decoration: const InputDecoration(labelText: '分鐘'),
                        items: [0, 15, 30, 45].map((m) => DropdownMenuItem(value: m, child: Text('$m'))).toList(),
                        onChanged: (v) => setState(() => goalMinutes = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final provider = context.read<AppProvider>();
                if (subject == null) {
                  provider.addSubject(Subject(
                    id: _uuid.v4(),
                    name: nameCtrl.text.trim(),
                    colorValue: selectedColor,
                    weeklyGoalMinutes: goalHours * 60 + goalMinutes,
                  ));
                } else {
                  subject.name = nameCtrl.text.trim();
                  subject.colorValue = selectedColor;
                  subject.weeklyGoalMinutes = goalHours * 60 + goalMinutes;
                  provider.updateSubject(subject);
                }
                Navigator.pop(ctx);
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除科目'),
        content: Text('確定要刪除「${subject.name}」？相關的讀書時段也會一併刪除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AppProvider>().deleteSubject(subject.id);
              Navigator.pop(ctx);
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}
