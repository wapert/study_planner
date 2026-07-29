import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/account_screen.dart';

/// Returns the capitalised first letter of [email], or '?' if unavailable.
String initialFor(String? email) {
  final e = email?.trim() ?? '';
  return e.isEmpty ? '?' : e.characters.first.toUpperCase();
}

/// Top-right account button showing the user's email initial. Opens the
/// 帳號與同步 (Account & Sync) screen. Shared across the main tabs.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthService>().email;
    return IconButton(
      tooltip: '帳號與同步',
      padding: EdgeInsets.zero,
      icon: CircleAvatar(
        radius: 15,
        // Same grey the bottom NavigationBar uses.
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Text(
          initialFor(email),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      ),
    );
  }
}
