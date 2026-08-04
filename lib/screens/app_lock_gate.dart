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

  /// Showing the lock UI. Also raised while backgrounded so the OS
  /// app-switcher snapshot never exposes the user's data.
  bool _locked = false;

  /// Whether the user has passed a biometric check in this session. Kept
  /// separate from [_locked] so returning quickly from the app switcher can
  /// restore an *already authenticated* session without re-prompting, while a
  /// never-authenticated lock still requires the prompt.
  bool _authenticated = false;

  bool _prompting = false;
  DateTime? _pausedAt;
  String _label = '生物辨識';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final lockEnabled = context.read<AppProvider>().appLockEnabled;

    if (lockEnabled && BiometricService.recentlyAuthenticated()) {
      // Arrived straight from a biometric sign-in on the login screen —
      // prompting again immediately would be a second, redundant check.
      _locked = false;
      _authenticated = true;
    } else {
      // Lock synchronously, before the first frame is painted. Deferring this
      // to a post-frame callback would render the real app content for a
      // frame (and for however long the async probe took) before the lock
      // appeared.
      _locked = lockEnabled;
      if (_locked) {
        // Prompt as soon as the lock screen is on screen.
        WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
      }
    }
    _loadLabel();
  }

  Future<void> _loadLabel() async {
    final label = await _bio.methodLabel();
    if (!mounted) return;
    setState(() => _label = label);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (!context.read<AppProvider>().appLockEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      // Cover the content before the OS takes its app-switcher snapshot.
      if (!_locked) setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null
          ? Duration.zero
          : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (!_locked) return;

      if (_authenticated && away <= _relockAfter) {
        // Briefly checked a notification — restore without re-prompting.
        setState(() => _locked = false);
      } else {
        // Never authenticated, or away long enough to re-lock.
        _authenticated = false;
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
    if (ok) {
      setState(() {
        _authenticated = true;
        _locked = false;
      });
    }
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
