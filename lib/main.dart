import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/subject.dart';
import 'models/study_session.dart';
import 'models/calendar_event.dart';
import 'models/todo_item.dart';
import 'models/user_profile.dart';
import 'models/chapter_plan.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/share_service.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);

  // Firebase is optional at boot: if it fails (e.g. offline first launch),
  // the app still runs locally with Hive.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed, running local-only: $e');
  }

  await Hive.initFlutter();
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(StudySessionAdapter());
  Hive.registerAdapter(CalendarEventAdapter());
  Hive.registerAdapter(TodoItemAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(ChapterPlanAdapter());

  final provider = AppProvider();
  await provider.init();

  final auth = AuthService();
  final sync = SyncService(provider: provider, auth: auth);
  final share = ShareService(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        Provider.value(value: auth),
        Provider.value(value: share),
        ChangeNotifierProvider.value(value: sync),
      ],
      child: StudyPlannerApp(firebaseReady: firebaseReady),
    ),
  );
}

class StudyPlannerApp extends StatelessWidget {
  final bool firebaseReady;
  const StudyPlannerApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '讀書計畫',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // App is designed light-only (今日/科目 pages use fixed white backgrounds),
      // so dark system theme would make other pages unreadable.
      themeMode: ThemeMode.light,
      home: AuthGate(firebaseReady: firebaseReady),
    );
  }
}
