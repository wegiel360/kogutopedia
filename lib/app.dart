import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/updater.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/login_screen.dart';

class KogutopediaApp extends ConsumerWidget {
  final UpdateInfo? pendingUpdate;

  const KogutopediaApp({super.key, this.pendingUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Kogutopedia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _buildHome(context, authState),
    );
  }

  Widget _buildHome(BuildContext context, AuthState authState) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
        ),
      );
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final dashboard = const DashboardScreen();

    if (pendingUpdate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppUpdater.showUpdateDialog(context, pendingUpdate!);
      });
    }

    return dashboard;
  }
}
