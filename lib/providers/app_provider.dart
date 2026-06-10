import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/calendar_event.dart';
import '../models/todo_item.dart';
import '../models/user_profile.dart';
import '../data/taiwan_calendar.dart';
import '../data/subject_presets.dart';
import '../utils/date_utils.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  late Box<Subject> _subjectBox;
  late Box<StudySession> _sessionBox;
  late Box<CalendarEvent> _eventBox;
  late Box<TodoItem> _todoBox;
  late Box<UserProfile> _profileBox;
  late Box<bool> _seededBox;

  List<Subject> get subjects => _subjectBox.values.toList();
  List<StudySession> get sessions => _sessionBox.values.toList();
  List<CalendarEvent> get events => _eventBox.values.toList();
  List<TodoItem> get todos => _todoBox.values.toList();

  UserProfile? get profile =>
      _profileBox.isNotEmpty ? _profileBox.values.first : null;

  bool get hasProfile => _profileBox.isNotEmpty;

  Future<void> init() async {
    _subjectBox = await Hive.openBox<Subject>('subjects');
    _sessionBox = await Hive.openBox<StudySession>('sessions');
    _eventBox = await Hive.openBox<CalendarEvent>('events');
    _todoBox = await Hive.openBox<TodoItem>('todos');
    _profileBox = await Hive.openBox<UserProfile>('profiles');
    _seededBox = await Hive.openBox<bool>('meta');

    if (_seededBox.get('seeded') != true) {
      await _seedDefaults();
      await _seededBox.put('seeded', true);
    }
  }

  Future<void> _seedDefaults() async {
    // Only seed calendar events on first launch; subjects are seeded via profile setup
    for (final e in TaiwanCalendar.allEvents) {
      final event = CalendarEvent(
        id: _uuid.v4(),
        title: e['title'] as String,
        date: (e['date'] as DateTime).dateOnly,
        typeIndex: (e['type'] as EventType).index,
      );
      await _eventBox.put(event.id, event);
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> saveProfile(UserProfile p) async {
    await _profileBox.clear();
    await _profileBox.put(p.id, p);
    notifyListeners();
  }

  /// Replace all subjects with the preset for [level].
  Future<void> applySubjectPreset(SchoolLevel level) async {
    await _subjectBox.clear();
    final presets = buildSubjects(level, () => _uuid.v4());
    for (final s in presets) {
      await _subjectBox.put(s.id, s);
    }
    notifyListeners();
  }

  /// Append preset subjects (skip names already present).
  Future<void> appendSubjectPreset(SchoolLevel level) async {
    final existing = _subjectBox.values.map((s) => s.name).toSet();
    final presets = buildSubjects(level, () => _uuid.v4())
        .where((s) => !existing.contains(s.name))
        .toList();
    for (final s in presets) {
      await _subjectBox.put(s.id, s);
    }
    notifyListeners();
  }

  // ── Subjects ──────────────────────────────────────────────────────────────

  Future<void> addSubject(Subject s) async {
    await _subjectBox.put(s.id, s);
    notifyListeners();
  }

  Future<void> updateSubject(Subject s) async {
    await s.save();
    notifyListeners();
  }

  Future<void> deleteSubject(String id) async {
    await _subjectBox.delete(id);
    final toDelete = _sessionBox.values.where((s) => s.subjectId == id).toList();
    for (final s in toDelete) { await s.delete(); }
    notifyListeners();
  }

  Subject? subjectById(String id) => _subjectBox.get(id);

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<void> addSession(StudySession s) async {
    await _sessionBox.put(s.id, s);
    notifyListeners();
  }

  Future<void> updateSession(StudySession s) async {
    await s.save();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _sessionBox.delete(id);
    notifyListeners();
  }

  Future<void> toggleSession(StudySession s) async {
    s.isCompleted = !s.isCompleted;
    await s.save();
    notifyListeners();
  }

  List<StudySession> sessionsForDay(DateTime day) {
    final d = day.dateOnly;
    return _sessionBox.values
        .where((s) => s.date.dateOnly.isSameDay(d))
        .toList()
      ..sort((a, b) => a.startHour != b.startHour
          ? a.startHour.compareTo(b.startHour)
          : a.startMinute.compareTo(b.startMinute));
  }

  List<StudySession> sessionsForWeek(DateTime weekStart) {
    final start = weekStart.dateOnly;
    final end = start.add(const Duration(days: 6));
    return _sessionBox.values
        .where((s) => !s.date.dateOnly.isBefore(start) && !s.date.dateOnly.isAfter(end))
        .toList();
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<void> addEvent(CalendarEvent e) async {
    await _eventBox.put(e.id, e);
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    await _eventBox.delete(id);
    notifyListeners();
  }

  List<CalendarEvent> eventsForDay(DateTime day) {
    final d = day.dateOnly;
    return _eventBox.values.where((e) => e.date.isSameDay(d)).toList();
  }

  // ── To-Do items ───────────────────────────────────────────────────────────

  Future<void> addTodo(TodoItem t) async {
    await _todoBox.put(t.id, t);
    notifyListeners();
  }

  Future<void> updateTodo(TodoItem t) async {
    await t.save();
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
    await _todoBox.delete(id);
    notifyListeners();
  }

  Future<void> toggleTodo(TodoItem t, DateTime date) async {
    t.toggleOn(date);
    await t.save();
    notifyListeners();
  }

  /// All todos active on [date] (weekday matches or no weekday filter).
  List<TodoItem> todosForDay(DateTime date) =>
      _todoBox.values.where((t) => t.activeOn(date)).toList();

  /// Todos for a specific subject on [date].
  List<TodoItem> todosForSubjectDay(String subjectId, DateTime date) =>
      _todoBox.values
          .where((t) => t.subjectId == subjectId && t.activeOn(date))
          .toList();

  /// Todos with no subject assigned, active on [date].
  List<TodoItem> generalTodosForDay(DateTime date) =>
      _todoBox.values
          .where((t) => t.subjectId == null && t.activeOn(date))
          .toList();

  // ── Progress stats ────────────────────────────────────────────────────────

  Map<String, int> weeklyMinutesPerSubject(DateTime weekStart) {
    final sessions = sessionsForWeek(weekStart);
    final Map<String, int> result = {};
    for (final s in sessions.where((s) => s.isCompleted)) {
      result[s.subjectId] = (result[s.subjectId] ?? 0) + s.durationMinutes;
    }
    return result;
  }

  int totalMinutesThisWeek(DateTime weekStart) {
    return sessionsForWeek(weekStart)
        .where((s) => s.isCompleted)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  double subjectGoalProgress(String subjectId, DateTime weekStart) {
    final subject = subjectById(subjectId);
    if (subject == null || subject.weeklyGoalMinutes == 0) return 0;
    final done = weeklyMinutesPerSubject(weekStart)[subjectId] ?? 0;
    return (done / subject.weeklyGoalMinutes).clamp(0.0, 1.0);
  }
}
