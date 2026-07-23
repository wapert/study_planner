import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/calendar_event.dart';
import '../models/todo_item.dart';
import '../models/user_profile.dart';
import '../models/chapter_plan.dart';

/// Firestore collection names (subcollections under users/{uid}).
class Collections {
  static const subjects = 'subjects';
  static const sessions = 'sessions';
  static const events = 'events';
  static const todos = 'todos';
  static const profiles = 'profiles';
  static const chapterPlans = 'chapterPlans';

  static const all = [
    subjects,
    sessions,
    events,
    todos,
    profiles,
    chapterPlans,
  ];
}

int _millis(DateTime d) => d.millisecondsSinceEpoch;
DateTime _date(dynamic v) =>
    DateTime.fromMillisecondsSinceEpoch((v as num).toInt());

// ── Subject ────────────────────────────────────────────────────────────────
Map<String, dynamic> subjectToMap(Subject s) => {
      'id': s.id,
      'name': s.name,
      'colorValue': s.colorValue,
      'weeklyGoalMinutes': s.weeklyGoalMinutes,
    };

Subject subjectFromMap(Map<String, dynamic> m) => Subject(
      id: m['id'] as String,
      name: m['name'] as String,
      colorValue: (m['colorValue'] as num).toInt(),
      weeklyGoalMinutes: (m['weeklyGoalMinutes'] as num?)?.toInt() ?? 120,
    );

// ── StudySession ─────────────────────────────────────────────────────────────
Map<String, dynamic> sessionToMap(StudySession s) => {
      'id': s.id,
      'subjectId': s.subjectId,
      'date': _millis(s.date),
      'startHour': s.startHour,
      'startMinute': s.startMinute,
      'durationMinutes': s.durationMinutes,
      'note': s.note,
      'isCompleted': s.isCompleted,
    };

StudySession sessionFromMap(Map<String, dynamic> m) => StudySession(
      id: m['id'] as String,
      subjectId: m['subjectId'] as String,
      date: _date(m['date']),
      startHour: (m['startHour'] as num).toInt(),
      startMinute: (m['startMinute'] as num).toInt(),
      durationMinutes: (m['durationMinutes'] as num).toInt(),
      note: (m['note'] as String?) ?? '',
      isCompleted: (m['isCompleted'] as bool?) ?? false,
    );

// ── CalendarEvent ─────────────────────────────────────────────────────────────
Map<String, dynamic> eventToMap(CalendarEvent e) => {
      'id': e.id,
      'title': e.title,
      'date': _millis(e.date),
      'typeIndex': e.typeIndex,
      'note': e.note,
    };

CalendarEvent eventFromMap(Map<String, dynamic> m) => CalendarEvent(
      id: m['id'] as String,
      title: m['title'] as String,
      date: _date(m['date']),
      typeIndex: (m['typeIndex'] as num).toInt(),
      note: (m['note'] as String?) ?? '',
    );

// ── TodoItem ─────────────────────────────────────────────────────────────────
Map<String, dynamic> todoToMap(TodoItem t) => {
      'id': t.id,
      'title': t.title,
      'subjectId': t.subjectId,
      'weekdays': t.weekdays,
      'completedDateKeys': t.completedDateKeys,
    };

TodoItem todoFromMap(Map<String, dynamic> m) => TodoItem(
      id: m['id'] as String,
      title: m['title'] as String,
      subjectId: m['subjectId'] as String?,
      weekdays: ((m['weekdays'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
      completedDateKeys: ((m['completedDateKeys'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
    );

// ── UserProfile ───────────────────────────────────────────────────────────────
Map<String, dynamic> profileToMap(UserProfile p) => {
      'id': p.id,
      'name': p.name,
      'schoolLevelIndex': p.schoolLevelIndex,
    };

UserProfile profileFromMap(Map<String, dynamic> m) => UserProfile(
      id: m['id'] as String,
      name: m['name'] as String,
      schoolLevelIndex: (m['schoolLevelIndex'] as num).toInt(),
    );

// ── ChapterPlan ───────────────────────────────────────────────────────────────
Map<String, dynamic> chapterPlanToMap(ChapterPlan c) => {
      'id': c.id,
      'subjectId': c.subjectId,
      'startNum': c.startNum,
      'endNum': c.endNum,
      'unitIndex': c.unitIndex,
      'studyDays': c.studyDays,
      'completedKeys': c.completedKeys,
      'startDateKey': c.startDateKey,
      'endDateKey': c.endDateKey,
    };

ChapterPlan chapterPlanFromMap(Map<String, dynamic> m) => ChapterPlan(
      id: m['id'] as String,
      subjectId: m['subjectId'] as String,
      startNum: (m['startNum'] as num).toInt(),
      endNum: (m['endNum'] as num).toInt(),
      unitIndex: (m['unitIndex'] as num?)?.toInt() ?? 0,
      studyDays: ((m['studyDays'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
      completedKeys: ((m['completedKeys'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      startDateKey: (m['startDateKey'] as num).toInt(),
      endDateKey: (m['endDateKey'] as num).toInt(),
    );

/// Serialize any known record by collection name.
Map<String, dynamic> toMapFor(String collection, dynamic obj) {
  switch (collection) {
    case Collections.subjects:
      return subjectToMap(obj as Subject);
    case Collections.sessions:
      return sessionToMap(obj as StudySession);
    case Collections.events:
      return eventToMap(obj as CalendarEvent);
    case Collections.todos:
      return todoToMap(obj as TodoItem);
    case Collections.profiles:
      return profileToMap(obj as UserProfile);
    case Collections.chapterPlans:
      return chapterPlanToMap(obj as ChapterPlan);
    default:
      throw ArgumentError('Unknown collection $collection');
  }
}

/// Deserialize any known record by collection name.
dynamic fromMapFor(String collection, Map<String, dynamic> m) {
  switch (collection) {
    case Collections.subjects:
      return subjectFromMap(m);
    case Collections.sessions:
      return sessionFromMap(m);
    case Collections.events:
      return eventFromMap(m);
    case Collections.todos:
      return todoFromMap(m);
    case Collections.profiles:
      return profileFromMap(m);
    case Collections.chapterPlans:
      return chapterPlanFromMap(m);
    default:
      throw ArgumentError('Unknown collection $collection');
  }
}
