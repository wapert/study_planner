import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'plan_screen.dart';
import 'progress_screen.dart';
import 'subjects_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    TodayScreen(),
    CalendarScreen(),
    PlanScreen(),
    ProgressScreen(),
    SubjectsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: '今日'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '行事曆'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: '讀書計畫'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '進度'),
          NavigationDestination(icon: Icon(Icons.book), label: '科目'),
        ],
      ),
    );
  }
}
