import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/dashboard_screen.dart';

class KogutopediaApp extends StatelessWidget {
  const KogutopediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kogutopedia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
