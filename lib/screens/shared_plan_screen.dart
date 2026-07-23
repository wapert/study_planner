import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/chapter_plan.dart';
import '../models/todo_item.dart';
import '../services/share_service.dart';
import '../services/firestore_serializers.dart';

const _blue = Color(0xFF1565C0);

/// Read-only view of another user's plan (subjects, chapter plans, todos).
class SharedPlanScreen extends StatefulWidget {
  final OwnerEntry owner;
  final ShareService share;
  const SharedPlanScreen(
      {super.key, required this.owner, required this.share});

  @override
  State<SharedPlanScreen> createState() => _SharedPlanScreenState();
}

class _SharedPlanScreenState extends State<SharedPlanScreen> {
  late Future<Map<String, List<dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.share.loadOwnerData(widget.owner.ownerUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.owner.ownerEmail),
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, List<dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('無法載入：${snap.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            );
          }
          final data = snap.data!;
          final subjects =
              (data[Collections.subjects] ?? []).cast<Subject>();
          final plans =
              (data[Collections.chapterPlans] ?? []).cast<ChapterPlan>();
          final todos = (data[Collections.todos] ?? []).cast<TodoItem>();

          if (subjects.isEmpty && plans.isEmpty && todos.isEmpty) {
            return Center(
              child: Text('這位使用者尚無讀書計畫',
                  style: TextStyle(color: Colors.grey.shade500)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined,
                        size: 16, color: _blue),
                    const SizedBox(width: 8),
                    Text('唯讀檢視',
                        style: TextStyle(
                            fontSize: 13,
                            color: _blue,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('科目與章節計畫',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (subjects.isEmpty)
                Text('無科目',
                    style: TextStyle(color: Colors.grey.shade500)),
              ...subjects.map((s) {
                final plan = plans
                    .where((p) => p.subjectId == s.id && !p.isExpired)
                    .cast<ChapterPlan?>()
                    .firstWhere((_) => true, orElse: () => null);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Color(s.colorValue), radius: 12),
                    title: Text(s.name),
                    subtitle: plan == null
                        ? Text('每週目標 ${s.weeklyGoalMinutes ~/ 60} 小時')
                        : Text(
                            '${plan.fullRangeLabel}（${plan.dateRangeLabel}）'),
                  ),
                );
              }),
              if (todos.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('待辦事項',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...todos.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_box_outline_blank,
                          size: 20),
                      title: Text(t.title),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
