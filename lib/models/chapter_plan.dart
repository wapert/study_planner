import 'package:hive_flutter/hive_flutter.dart';

part 'chapter_plan.g.dart';

@HiveType(typeId: 5)
class ChapterPlan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  /// Starting chapter / page number (e.g. 1).
  @HiveField(2)
  int startNum;

  @HiveField(3)
  List<int> studyDays; // 1=Mon … 7=Sun, kept sorted

  @HiveField(4)
  List<int> completedKeys; // yyyyMMdd for each day marked done

  /// Ending chapter / page number (e.g. 10).
  @HiveField(5)
  int endNum;

  /// 0 = 課, 1 = 頁
  @HiveField(6)
  int unitIndex;

  ChapterPlan({
    required this.id,
    required this.subjectId,
    required this.startNum,
    required this.endNum,
    required this.studyDays,
    this.unitIndex = 0,
    List<int>? completedKeys,
  }) : completedKeys = completedKeys ?? [];

  String get unitLabel => unitIndex == 0 ? '課' : '頁';
  int get totalCount => (endNum - startNum + 1).clamp(1, 99999);
  String get fullRangeLabel => '第$startNum$unitLabel～第$endNum$unitLabel';

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

  /// Returns the (start, end) number range for the study day at sorted index [i].
  (int, int) rangeForDayIndex(int i) {
    if (studyDays.isEmpty) return (startNum, endNum);
    final total = totalCount;
    final n = studyDays.length;
    final base = total ~/ n;
    final extra = total % n;
    int start = startNum;
    for (int j = 0; j < i; j++) {
      start += j < extra ? base + 1 : base;
    }
    final count = i < extra ? base + 1 : base;
    return (start, start + count - 1);
  }

  /// Returns (start, end) for a specific calendar date, or null if not a study day.
  (int, int)? rangeForDate(DateTime date) {
    if (!isStudyDay(date) || studyDays.isEmpty) return null;
    final sorted = List<int>.from(studyDays)..sort();
    final i = sorted.indexOf(date.weekday);
    if (i < 0) return null;
    return rangeForDayIndex(i);
  }

  /// Human-readable range string for a specific date (e.g. "第5課～第7課").
  String rangeLabelForDate(DateTime date) {
    final r = rangeForDate(date);
    if (r == null) return '';
    return '第${r.$1}$unitLabel～第${r.$2}$unitLabel';
  }

  /// Count of chapters/pages assigned to [date] (for stats).
  int chaptersForDate(DateTime date) {
    final r = rangeForDate(date);
    if (r == null) return 0;
    return r.$2 - r.$1 + 1;
  }
}
