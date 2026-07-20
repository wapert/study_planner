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

  /// Plan validity period, stored as yyyyMMdd.
  @HiveField(7)
  int startDateKey;

  @HiveField(8)
  int endDateKey;

  ChapterPlan({
    required this.id,
    required this.subjectId,
    required this.startNum,
    required this.endNum,
    required this.studyDays,
    required this.startDateKey,
    required this.endDateKey,
    this.unitIndex = 0,
    List<int>? completedKeys,
  }) : completedKeys = completedKeys ?? [];

  String get unitLabel => unitIndex == 0 ? '課' : '頁';
  int get totalCount => (endNum - startNum + 1).clamp(1, 99999);
  String get fullRangeLabel => '第$startNum$unitLabel～第$endNum$unitLabel';

  static int dateKeyOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime dateFromKey(int key) =>
      DateTime(key ~/ 10000, (key % 10000) ~/ 100, key % 100);

  DateTime get startDate => dateFromKey(startDateKey);
  DateTime get endDate => dateFromKey(endDateKey);

  String get dateRangeLabel =>
      '${startDate.month}/${startDate.day}～${endDate.month}/${endDate.day}';

  /// True when the whole plan period is already in the past.
  bool get isExpired => dateKeyOf(DateTime.now()) > endDateKey;

  bool inPeriod(DateTime date) {
    final k = dateKeyOf(date);
    return k >= startDateKey && k <= endDateKey;
  }

  bool isStudyDay(DateTime date) => studyDays.contains(date.weekday);

  /// A date gets an assignment only when it is a study weekday AND inside the period.
  bool activeOn(DateTime date) => inPeriod(date) && isStudyDay(date);

  bool isCompletedOn(DateTime date) => completedKeys.contains(dateKeyOf(date));

  void toggleOn(DateTime date) {
    final key = dateKeyOf(date);
    if (completedKeys.contains(key)) {
      completedKeys.remove(key);
    } else {
      completedKeys.add(key);
    }
  }

  /// All concrete study dates inside the plan period, in order.
  List<DateTime> get allStudyDates {
    final result = <DateTime>[];
    var d = startDate;
    final end = endDate;
    while (!d.isAfter(end)) {
      if (studyDays.contains(d.weekday)) result.add(d);
      d = d.add(const Duration(days: 1));
    }
    return result;
  }

  /// Returns (start, end) chapter numbers for a specific calendar date,
  /// or null if the date has no assignment. Distributes totalCount across
  /// all study dates in the period, front-loading the remainder.
  (int, int)? rangeForDate(DateTime date) {
    if (!activeOn(date)) return null;
    final dates = allStudyDates;
    if (dates.isEmpty) return null;
    final target = dateKeyOf(date);
    final i = dates.indexWhere((d) => dateKeyOf(d) == target);
    if (i < 0) return null;

    final total = totalCount;
    final n = dates.length;
    final base = total ~/ n;
    final extra = total % n;
    int start = startNum;
    for (int j = 0; j < i; j++) {
      start += j < extra ? base + 1 : base;
    }
    final count = i < extra ? base + 1 : base;
    if (count <= 0) return null;
    return (start, start + count - 1);
  }

  /// Human-readable range string for a specific date (e.g. "第5課～第7課").
  String rangeLabelForDate(DateTime date) {
    final r = rangeForDate(date);
    if (r == null) return '';
    if (r.$1 == r.$2) return '第${r.$1}$unitLabel';
    return '第${r.$1}$unitLabel～第${r.$2}$unitLabel';
  }

  /// Count of chapters/pages assigned to [date] (for stats).
  int chaptersForDate(DateTime date) {
    final r = rangeForDate(date);
    if (r == null) return 0;
    return r.$2 - r.$1 + 1;
  }
}
