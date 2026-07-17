import 'package:hive_flutter/hive_flutter.dart';

part 'chapter_plan.g.dart';

@HiveType(typeId: 5)
class ChapterPlan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  int weeklyChapters;

  @HiveField(3)
  List<int> studyDays; // 1=Mon … 7=Sun, kept sorted

  @HiveField(4)
  List<int> completedKeys; // yyyyMMdd for each day marked done

  ChapterPlan({
    required this.id,
    required this.subjectId,
    required this.weeklyChapters,
    required this.studyDays,
    List<int>? completedKeys,
  }) : completedKeys = completedKeys ?? [];

  int _dateKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  bool isStudyDay(DateTime date) => studyDays.contains(date.weekday);

  bool isCompletedOn(DateTime date) => completedKeys.contains(_dateKey(date));

  void toggleOn(DateTime date) {
    final key = _dateKey(date);
    if (completedKeys.contains(key)) {
      completedKeys.remove(key);
    } else {
      completedKeys.add(key);
    }
  }

  /// How many chapters are assigned to [date].
  /// Distributes weeklyChapters across studyDays, front-loading the remainder.
  int chaptersForDate(DateTime date) {
    if (!isStudyDay(date) || studyDays.isEmpty || weeklyChapters == 0) return 0;
    final sorted = List<int>.from(studyDays)..sort();
    final i = sorted.indexOf(date.weekday);
    final base = weeklyChapters ~/ sorted.length;
    final extra = weeklyChapters % sorted.length;
    return i < extra ? base + 1 : base;
  }
}
