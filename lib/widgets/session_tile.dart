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
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        title: Text(subject?.name ?? '已刪除科目'),
        subtitle: Text(
          showDate
              ? '${session.date.month}/${session.date.day}  ${formatHHMM(session.startHour, session.startMinute)}  ${formatDuration(session.durationMinutes)}'
              : '${formatHHMM(session.startHour, session.startMinute)}  ${formatDuration(session.durationMinutes)}${session.note.isNotEmpty ? '  •  ${session.note}' : ''}',
        ),
        trailing: Checkbox(
          value: session.isCompleted,
          activeColor: color,
          onChanged: (_) => provider.toggleSession(session),
        ),
      ),
    );
  }
}
