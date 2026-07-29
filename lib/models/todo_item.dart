import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 3)
class TodoItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? subjectId; // null = no subject

  /// Weekdays this todo recurs on: 1=Mon … 7=Sun. Empty = every day.
  /// Ignored when [onDateKey] is set (one-time todo).
  @HiveField(3)
  List<int> weekdays;

  /// Dates (yyyy-MM-dd as int yyyyMMdd) on which this item was checked off.
  @HiveField(4)
  List<int> completedDateKeys;

  /// When set (yyyyMMdd), this is a one-time todo active only on that date;
  /// [weekdays] is ignored. Null = recurring todo (uses [weekdays]).
  @HiveField(5)
  int? onDateKey;

  TodoItem({
    required this.id,
    required this.title,
    this.subjectId,
    required this.weekdays,
    List<int>? completedDateKeys,
    this.onDateKey,
  }) : completedDateKeys = completedDateKeys ?? [];

  static int dateKeyOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  static int _key(DateTime d) => dateKeyOf(d);

  bool get isRepeating => onDateKey == null;

  bool isCompletedOn(DateTime date) => completedDateKeys.contains(_key(date));

  void toggleOn(DateTime date) {
    final k = _key(date);
    if (completedDateKeys.contains(k)) {
      completedDateKeys.remove(k);
    } else {
      completedDateKeys.add(k);
    }
  }

  bool activeOn(DateTime date) {
    if (onDateKey != null) return onDateKey == _key(date);
    return weekdays.isEmpty || weekdays.contains(date.weekday);
  }
}
