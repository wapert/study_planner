extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime get weekStart {
    final weekday = this.weekday % 7; // Sunday=0
    return subtract(Duration(days: weekday)).dateOnly;
  }
}

String formatHHMM(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes 分鐘';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h 小時' : '$h 小時 $m 分鐘';
}
