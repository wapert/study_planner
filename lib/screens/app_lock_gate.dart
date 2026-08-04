import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/biometric_service.dart';

const _blue = Color(0xFF1E88E5);

/// Grace period: coming back within this window (e.g. after glancing at a
/// notification) doesn't re-prompt. Longer absences re-lock.
const _relockAfter = Duration(seconds: 30);

/// Wraps the signed-in app and requires biometric (or device passcode)
/// authentication when 應用程式鎖 is enabled.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final _bio = BiometricService();
  bool _locked = false;
  bool _prompting = false;
  DateTime? _pausedAt;
  String _label = '生物辨識';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Read the pref after the first frame so context is safe to use.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _label = await _bio.methodLabel();
      if (!mounted) return;
      if (context.read<AppProvider>().appLockEnabled) {
        setState(() => _locked = true);
        _unlock();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final enabled = context.read<AppProvider>().appLockEnabled;
    if (!enabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null
          ? Duration.zero
          : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (!_locked && away > _relockAfter) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    final ok = await _bio.authenticate();
    _prompting = false;
    if (!mounted) return;
    if (ok) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    // If the user turns the lock off while unlocked, nothing to do.
    final enabled = context.watch<AppProvider>().appLockEnabled;
    if (!enabled || !_locked) return widget.child;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: _blue),
              const SizedBox(height: 20),
              const Text('讀書計畫已鎖定',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('請使用 $_label 解鎖',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 28),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.fingerprint),
                label: const Text('解鎖'),
                onPressed: _unlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
