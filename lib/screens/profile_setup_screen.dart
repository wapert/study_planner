import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import '../data/subject_presets.dart';

const _uuid = Uuid();

class ProfileSetupScreen extends StatefulWidget {
  /// If [existing] is provided this is an edit dialog, not first-launch.
  final UserProfile? existing;
  const ProfileSetupScreen({super.key, this.existing});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nameCtrl;
  SchoolLevel? _level;
  bool _applyPreset = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _level = widget.existing?.schoolLevel;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isEdit
          ? AppBar(
              title: const Text('編輯個人資料'),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEdit) ...[
                const Text('👋 歡迎使用讀書計畫',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('先設定你的基本資料，幫你快速建立科目',
                    style:
                        TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                const SizedBox(height: 36),
              ],

              // Name
              const Text('姓名', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                autofocus: !_isEdit,
                decoration: InputDecoration(
                  hintText: '輸入你的名字',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 28),

              // School level
              const Text('學制', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: SchoolLevel.values.map((level) {
                  final selected = _level == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _level = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(level.emoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text(
                              level.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Preset subjects preview
              if (_level != null && _level != SchoolLevel.custom) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Text('預設科目',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (_isEdit)
                      Row(
                        children: [
                          Checkbox(
                            value: _applyPreset,
                            onChanged: (v) =>
                                setState(() => _applyPreset = v ?? true),
                          ),
                          const Text('套用預設',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presetsFor(_level!).map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(p.colorValue).withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Color(p.colorValue).withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(p.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(p.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(p.colorValue),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 40),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _canSave ? _save : null,
                  child: Text(
                    _isEdit ? '儲存' : '開始使用',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              if (!_isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _skipSetup(context),
                    child: Text('略過',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _level != null;

  Future<void> _save() async {
    final provider = context.read<AppProvider>();
    final profile = UserProfile(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text.trim(),
      schoolLevelIndex: _level!.index,
    );
    await provider.saveProfile(profile);

    if (_level != SchoolLevel.custom &&
        (!_isEdit || _applyPreset)) {
      if (_isEdit && provider.subjects.isNotEmpty) {
        // Ask replace or append
        if (!mounted) return;
        final choice = await _showReplaceDialog();
        if (choice == null) return;
        if (choice) {
          await provider.applySubjectPreset(_level!);
        } else {
          await provider.appendSubjectPreset(_level!);
        }
      } else {
        await provider.applySubjectPreset(_level!);
      }
    }

    if (!mounted) return;
    if (_isEdit) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _skipSetup(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<bool?> _showReplaceDialog() {
    return showDialog<bool>(
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
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('全部取代')),
        ],
      ),
    );
  }
}
