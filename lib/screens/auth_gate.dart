import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import 'login_screen.dart';

/// Decides what to show based on Firebase auth state:
/// - Firebase unavailable  → local-only app (offline fallback)
/// - signed out            → LoginScreen
/// - signed in             → profile setup (first launch) or HomeScreen
class AuthGate extends StatelessWidget {
  final bool firebaseReady;
  const AuthGate({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    // Offline / Firebase failed to init: run the app locally without auth.
    if (!firebaseReady) return const _AppRoot();

    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const _AppRoot();
      },
    );
  }
}

/// The signed-in (or offline) app: first-launch profile setup, then home.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final showSetup = !provider.hasProfile && !provider.profileSetupDismissed;
    return showSetup ? const ProfileSetupScreen() : const HomeScreen();
  }
}
