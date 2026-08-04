import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/credential_store.dart';

const _blue = Color(0xFF1E88E5);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  final _bio = BiometricService();
  bool _bioAvailable = false;
  String? _savedEmail;
  String _bioLabel = '生物辨識';
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final store = context.read<CredentialStore>();
    final auth = context.read<AuthService>();

    // If the user just chose 登出, don't immediately ask them to sign back
    // in. The button stays available for when they actually want it.
    final deliberateSignOut = auth.justSignedOut;
    auth.justSignedOut = false;

    final hasCreds = await store.hasCredentials();
    if (!hasCreds) return;
    final available = await _bio.isAvailable();
    final label = await _bio.methodLabel();
    final email = await store.savedEmail();
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _bioLabel = label;
      _savedEmail = email;
      if (email != null) _emailCtrl.text = email;
    });
    // Auto-prompt only on a fresh launch, never right after a sign-out.
    if (available && !deliberateSignOut && !_autoPrompted) {
      _autoPrompted = true;
      _biometricSignIn();
    }
  }

  Future<void> _biometricSignIn() async {
    if (_busy) return;
    final store = context.read<CredentialStore>();
    // Capture before the await so BuildContext isn't used across the gap.
    final auth = context.read<AuthService>();
    final ok = await _bio.authenticate(reason: '驗證身分以登入讀書計畫');
    if (!ok || !mounted) return;

    final creds = await store.read();
    if (creds == null) {
      if (mounted) setState(() => _error = '找不到已儲存的登入資訊，請手動登入');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.signIn(creds.$1, creds.$2);
      // AuthGate reacts to the auth state change.
    } catch (e) {
      // Most likely the password was changed on another device — the stored
      // copy is now useless, so drop it rather than prompting forever.
      await store.clear();
      if (!mounted) return;
      setState(() {
        _bioAvailable = false;
        _error = '儲存的密碼已失效，請重新輸入密碼登入';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (email.isEmpty || pw.isEmpty) {
      setState(() => _error = '請輸入電子郵件與密碼');
      return;
    }
    if (_isSignUp && pw.length < 6) {
      setState(() => _error = '密碼至少需要 6 個字元');
      return;
    }
    if (_isSignUp && pw != _pwConfirmCtrl.text) {
      setState(() => _error = '兩次輸入的密碼不一致');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      if (_isSignUp) {
        await auth.signUp(email, pw);
      } else {
        await auth.signIn(email, pw);
      }
      // AuthGate reacts to the auth state change automatically.
    } catch (e) {
      setState(() => _error = AuthService.messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '請先輸入電子郵件');
      return;
    }
    try {
      await context.read<AuthService>().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已寄送重設密碼郵件至 $email')),
      );
    } catch (e) {
      setState(() => _error = AuthService.messageFor(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Icon(Icons.menu_book_rounded, size: 56, color: _blue),
                  const SizedBox(height: 16),
                  const Text('讀書計畫',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp ? '建立帳號以同步你的讀書計畫' : '登入以同步你的讀書計畫',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: _fieldDeco('電子郵件', Icons.email_outlined),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextField(
                    controller: _pwCtrl,
                    obscureText: _obscure,
                    textInputAction: _isSignUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) => _isSignUp ? null : _submit(),
                    decoration:
                        _fieldDeco(_isSignUp ? '設定密碼' : '密碼', Icons.lock_outline)
                            .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),

                  // Confirm password (sign-up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pwConfirmCtrl,
                      obscureText: _obscure,
                      onSubmitted: (_) => _submit(),
                      decoration: _fieldDeco('確認密碼', Icons.lock_outline),
                    ),
                  ],

                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _forgotPassword,
                        child: const Text('忘記密碼？',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 18, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white),
                            )
                          : Text(_isSignUp ? '註冊' : '登入',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  // Biometric sign-in (only when credentials were saved)
                  if (_bioAvailable && !_isSignUp) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('或',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          side: const BorderSide(color: _blue, width: 1.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.fingerprint, size: 22),
                        label: Text('使用 $_bioLabel 登入',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        onPressed: _busy ? null : _biometricSignIn,
                      ),
                    ),
                    if (_savedEmail != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_savedEmail!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ),
                  ],

                  const SizedBox(height: 18),

                  // Toggle sign in / sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isSignUp ? '已經有帳號了？' : '還沒有帳號？',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600)),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _error = null;
                                  _pwConfirmCtrl.clear();
                                }),
                        child: Text(_isSignUp ? '登入' : '註冊',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _blue)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.6),
        ),
      );
}
