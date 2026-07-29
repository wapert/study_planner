import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_session.dart';
import '../providers/app_provider.dart';
import '../utils/date_utils.dart';

class SessionTile extends StatelessWidget {
  final StudySession session;
  final bool showDate;
  const SessionTile({super.key, required this.session, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final subject = provider.subjectById(session.subjectId);
    final color = subject != null ? Color(subject.colorValue) : Colors.grey;

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteSession(session.id),
      child: ListTile(
        onTap: () => provider.toggleSession(session),
        // Completion checkbox leads the row, matching the other pages.
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: session.isCompleted ? color : Colors.transparent,
                border: Border.all(
                  color: session.isCompleted ? color : Colors.grey.shade400,
                  width: 1.8,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: session.isCompleted
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
        title: Text(
          subject?.name ?? '已刪除科目',
          style: TextStyle(
            color: session.isCompleted ? Colors.grey : null,
            decoration:
                session.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          showDate
              ? '${session.date.month}/${session.date.day}  ${formatHHMM(session.startHour, session.startMinute)}  ${formatDuration(session.durationMinutes)}'
              : '${formatHHMM(session.startHour, session.startMinute)}  ${formatDuration(session.durationMinutes)}${session.note.isNotEmpty ? '  •  ${session.note}' : ''}',
        ),
      ),
    );
  }
}
