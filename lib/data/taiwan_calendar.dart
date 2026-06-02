import '../models/calendar_event.dart';

class TaiwanCalendar {
  static List<Map<String, dynamic>> get nationalHolidays2025_2026 => [
    // 2025
    {'title': '中華民國開國紀念日', 'date': DateTime(2025, 1, 1), 'type': EventType.holiday},
    {'title': '農曆除夕', 'date': DateTime(2025, 1, 28), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2025, 1, 29), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2025, 1, 30), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2025, 1, 31), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2025, 2, 1), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2025, 2, 2), 'type': EventType.holiday},
    {'title': '228和平紀念日', 'date': DateTime(2025, 2, 28), 'type': EventType.holiday},
    {'title': '兒童節', 'date': DateTime(2025, 4, 4), 'type': EventType.holiday},
    {'title': '清明節', 'date': DateTime(2025, 4, 4), 'type': EventType.holiday},
    {'title': '勞動節', 'date': DateTime(2025, 5, 1), 'type': EventType.holiday},
    {'title': '端午節', 'date': DateTime(2025, 5, 31), 'type': EventType.holiday},
    {'title': '中秋節', 'date': DateTime(2025, 10, 6), 'type': EventType.holiday},
    {'title': '國慶日', 'date': DateTime(2025, 10, 10), 'type': EventType.holiday},
    // 2026
    {'title': '中華民國開國紀念日', 'date': DateTime(2026, 1, 1), 'type': EventType.holiday},
    {'title': '農曆除夕', 'date': DateTime(2026, 2, 16), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2026, 2, 17), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2026, 2, 18), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2026, 2, 19), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2026, 2, 20), 'type': EventType.holiday},
    {'title': '春節', 'date': DateTime(2026, 2, 21), 'type': EventType.holiday},
    {'title': '228和平紀念日', 'date': DateTime(2026, 2, 28), 'type': EventType.holiday},
    {'title': '兒童節', 'date': DateTime(2026, 4, 4), 'type': EventType.holiday},
    {'title': '清明節', 'date': DateTime(2026, 4, 5), 'type': EventType.holiday},
    {'title': '勞動節', 'date': DateTime(2026, 5, 1), 'type': EventType.holiday},
    {'title': '端午節', 'date': DateTime(2026, 6, 19), 'type': EventType.holiday},
  ];

  static List<Map<String, dynamic>> get schoolCalendar2025_2026 => [
    // 上學期 (Semester 1: Sep 2025 – Jan 2026)
    {'title': '上學期開學', 'date': DateTime(2025, 9, 1), 'type': EventType.schoolEvent},
    {'title': '第一次期中考', 'date': DateTime(2025, 10, 20), 'type': EventType.exam},
    {'title': '第一次期中考', 'date': DateTime(2025, 10, 21), 'type': EventType.exam},
    {'title': '第一次期中考', 'date': DateTime(2025, 10, 22), 'type': EventType.exam},
    {'title': '第一次期末考', 'date': DateTime(2026, 1, 5), 'type': EventType.exam},
    {'title': '第一次期末考', 'date': DateTime(2026, 1, 6), 'type': EventType.exam},
    {'title': '第一次期末考', 'date': DateTime(2026, 1, 7), 'type': EventType.exam},
    {'title': '上學期結束', 'date': DateTime(2026, 1, 21), 'type': EventType.schoolEvent},
    {'title': '寒假開始', 'date': DateTime(2026, 1, 22), 'type': EventType.holiday},
    // 下學期 (Semester 2: Feb – Jun 2026)
    {'title': '下學期開學', 'date': DateTime(2026, 2, 24), 'type': EventType.schoolEvent},
    {'title': '第二次期中考', 'date': DateTime(2026, 4, 13), 'type': EventType.exam},
    {'title': '第二次期中考', 'date': DateTime(2026, 4, 14), 'type': EventType.exam},
    {'title': '第二次期中考', 'date': DateTime(2026, 4, 15), 'type': EventType.exam},
    {'title': '第二次期末考', 'date': DateTime(2026, 6, 8), 'type': EventType.exam},
    {'title': '第二次期末考', 'date': DateTime(2026, 6, 9), 'type': EventType.exam},
    {'title': '第二次期末考', 'date': DateTime(2026, 6, 10), 'type': EventType.exam},
    {'title': '下學期結束', 'date': DateTime(2026, 6, 26), 'type': EventType.schoolEvent},
    {'title': '暑假開始', 'date': DateTime(2026, 6, 27), 'type': EventType.holiday},
  ];

  static List<Map<String, dynamic>> get allEvents =>
      [...nationalHolidays2025_2026, ...schoolCalendar2025_2026];
}
