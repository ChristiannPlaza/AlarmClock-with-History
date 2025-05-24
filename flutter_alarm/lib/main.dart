import 'package:flutter/material.dart';
import 'alarm.dart';
import 'stopwatch.dart';
import 'timer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF162B34),
        scaffoldBackgroundColor: const Color(0xFF162B34),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          background: Color(0xFF162B34),
        ),
      ),
      home: const NavigationScreen(),
    );
  }
}

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AlarmScreen(),
    const StopwatchScreen(),
    const TimerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
    );
  }
}
