import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../screens/account_screen.dart';

const _blue = Color(0xFF1E88E5);

/// Returns the capitalised first letter of [text], or '?' if unavailable.
String initialFor(String? text) {
  final t = text?.trim() ?? '';
  return t.isEmpty ? '?' : t.characters.first.toUpperCase();
}

/// Initial to show for the account: the profile name's first letter when a
/// name is set, otherwise the email's.
String accountInitial(BuildContext context) {
  final name = context.watch<AppProvider>().profile?.name.trim() ?? '';
  if (name.isNotEmpty) return initialFor(name);
  return initialFor(context.watch<AuthService>().email);
}

/// Top-right account button showing the user's initial. Opens the
/// 帳號與同步 (Account & Sync) screen. Shared across the main tabs.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '帳號與同步',
      padding: EdgeInsets.zero,
      icon: CircleAvatar(
        radius: 15,
        backgroundColor: _blue,
        child: Text(
          accountInitial(context),
          style: const TextStyle(
            color: Colors.white,
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
