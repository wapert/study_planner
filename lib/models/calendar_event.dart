import 'package:hive/hive.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 2)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int typeIndex;

  @HiveField(4)
  String note;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.typeIndex,
    this.note = '',
  });

  EventType get type => EventType.values[typeIndex];
}

enum EventType { exam, holiday, schoolEvent, personal }

extension EventTypeLabel on EventType {
  String get label {
    switch (this) {
      case EventType.exam:
        return '考試';
      case EventType.holiday:
        return '假日';
      case EventType.schoolEvent:
        return '學校活動';
      case EventType.personal:
        return '個人';
    }
  }

  int get colorValue {
    switch (this) {
      case EventType.exam:
        return 0xFFE53935;
      case EventType.holiday:
        return 0xFF43A047;
      case EventType.schoolEvent:
        return 0xFF1E88E5;
      case EventType.personal:
        return 0xFFFF8F00;
    }
  }
}
