import 'package:flutter/material.dart';
import '../screens/account_screen.dart';

/// Top-right account icon that opens the 帳號與同步 (Account & Sync) screen.
/// Shared across the main tabs so it sits in the same spot everywhere.
class AccountButton extends StatelessWidget {
  final Color? color;
  const AccountButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      color: color,
      tooltip: '帳號與同步',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      ),
    );
  }
}
