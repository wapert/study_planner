import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 1)
class StudySession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int startHour;

  @HiveField(4)
  int startMinute;

  @HiveField(5)
  int durationMinutes;

  @HiveField(6)
  String note;

  @HiveField(7)
  bool isCompleted;

  StudySession({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    this.note = '',
    this.isCompleted = false,
  });

  DateTime get startTime => DateTime(
        date.year,
        date.month,
        date.day,
        startHour,
        startMinute,
      );
}
