import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/subject.dart';
import '../models/chapter_plan.dart';
import '../models/user_profile.dart';
import '../data/subject_presets.dart';
import '../widgets/chapter_plan_sheet.dart';
import 'profile_setup_screen.dart';

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
    final provider = context.watch<AppProvider>();
    final subjects = provider.subjects;
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('科目管理'), centerTitle: false),
      body: ListView(
        children: [
          // ── Profile card ────────────────────────────────────────────────
          _ProfileCard(profile: profile),

          // ── Preset quick-apply bar ──────────────────────────────────────
          if (profile == null ||
              profile.schoolLevel == SchoolLevel.custom) ...[
            _PresetBar(
              label: '國中預設科目',
              level: SchoolLevel.junior,
              subjects: presetsFor(SchoolLevel.junior),
            ),
            const SizedBox(height: 4),
            _PresetBar(
              label: '高中預設科目',
              level: SchoolLevel.senior,
              subjects: presetsFor(SchoolLevel.senior),
            ),
          ] else
            _PresetBar(
              label: '${profile.schoolLevel.label}預設科目',
              level: profile.schoolLevel,
              subjects: presetsFor(profile.schoolLevel),
            ),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // ── Subject list ────────────────────────────────────────────────
          if (subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('尚無科目，請套用預設或自行新增')),
            )
          else
            ...subjects.expand((s) {
              final plan = provider.chapterPlanForSubject(s.id);
              return [
                _SubjectTile(
                  subject: s,
                  onEdit: () => _showSubjectDialog(context, subject: s),
                  onDelete: () => _confirmDelete(context, s),
                ),
                _ChapterPlanRow(
                  subject: s,
                  plan: plan,
                  onTap: () => showChapterPlanSheet(context, s, existing: plan),
                ),
              ];
            }),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新增科目'),
      ),
    );
  }

  // ── Subject dialog ────────────────────────────────────────────────────────

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
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: selectedColor == c
                            ? Border.all(width: 3, color: Colors.white)
                            : null,
                        boxShadow: selectedColor == c
                            ? [BoxShadow(
                                color: Color(c).withAlpha(120),
                                blurRadius: 6)]
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
                        items: List.generate(12, (i) =>
                            DropdownMenuItem(value: i, child: Text('$i'))),
                        onChanged: (v) => setState(() => goalHours = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: goalMinutes,
                        decoration: const InputDecoration(labelText: '分鐘'),
                        items: [0, 15, 30, 45].map((m) =>
                            DropdownMenuItem(value: m, child: Text('$m'))).toList(),
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

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserProfile? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('設定個人資料'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ProfileSetupScreen()),
          ),
        ),
      );
    }

    final p = profile!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(existing: p)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Text(
                  p.name.isNotEmpty
                      ? p.name.characters.first
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      '${p.schoolLevel.emoji} ${p.schoolLevel.label}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Preset quick-apply bar ────────────────────────────────────────────────────

class _PresetBar extends StatelessWidget {
  final String label;
  final SchoolLevel level;
  final List<SubjectPreset> subjects;

  const _PresetBar({
    required this.label,
    required this.level,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                _ApplyButton(level: level),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: subjects.map((p) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(p.colorValue).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Color(p.colorValue).withAlpha(70)),
                ),
                child: Text(p.name,
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(p.colorValue),
                        fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final SchoolLevel level;
  const _ApplyButton({required this.level});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: () => _apply(context),
      child: const Text('套用'),
    );
  }

  Future<void> _apply(BuildContext context) async {
    final provider = context.read<AppProvider>();
    if (provider.subjects.isEmpty) {
      await provider.applySubjectPreset(level);
      return;
    }
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('套用預設科目'),
        content: const Text('要取代目前所有科目，還是只新增缺少的科目？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('取消')),
          OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('新增缺少的')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('全部取代')),
        ],
      ),
    );
    if (choice == null) return;
    if (choice) {
      await provider.applySubjectPreset(level);
    } else {
      await provider.appendSubjectPreset(level);
    }
  }
}

// ── Chapter plan row (shown under each subject) ───────────────────────────────

const _wdShort = ['一', '二', '三', '四', '五', '六', '日'];

class _ChapterPlanRow extends StatelessWidget {
  final Subject subject;
  final ChapterPlan? plan;
  final VoidCallback onTap;

  const _ChapterPlanRow({
    required this.subject,
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
        child: plan == null
            ? Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    '+ 設定章節計畫',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 14, color: color.withAlpha(180)),
                  const SizedBox(width: 6),
                  Text(
                    plan!.fullRangeLabel,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  ...plan!.studyDays.map((wd) => Container(
                        margin: const EdgeInsets.only(right: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _wdShort[wd - 1],
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      )),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_outlined,
                      size: 13, color: Colors.grey.shade400),
                ],
              ),
      ),
    );
  }
}

// ── Subject tile ──────────────────────────────────────────────────────────────

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectTile({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: Color(subject.colorValue), radius: 14),
      title: Text(subject.name),
      subtitle: Text(
          '每週目標：${subject.weeklyGoalMinutes ~/ 60} 小時 ${subject.weeklyGoalMinutes % 60} 分鐘'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }
}
