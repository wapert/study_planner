import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'models/subject.dart';
import 'models/study_session.dart';
import 'models/calendar_event.dart';
import 'models/todo_item.dart';
import 'models/user_profile.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);
  await Hive.initFlutter();
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(StudySessionAdapter());
  Hive.registerAdapter(CalendarEventAdapter());
  Hive.registerAdapter(TodoItemAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  final provider = AppProvider();
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: StudyPlannerApp(showSetup: !provider.hasProfile),
    ),
  );
}

class StudyPlannerApp extends StatelessWidget {
  final bool showSetup;
  const StudyPlannerApp({super.key, required this.showSetup});

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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/home': (_) => const HomeScreen(),
      },
      home: showSetup ? const ProfileSetupScreen() : const HomeScreen(),
    );
  }
}
