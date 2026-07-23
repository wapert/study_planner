import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth for email/password accounts.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  String? get email => _auth.currentUser?.email;
  bool get isSignedIn => _auth.currentUser != null;

  /// Emits on every sign-in / sign-out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Re-authenticate with the current email + password. Firebase requires a
  /// recent login before sensitive operations like account deletion.
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('尚未登入');
    final cred =
        EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  /// Permanently delete the Firebase Auth account. Call after cloud data is
  /// removed and after a recent [reauthenticate].
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  /// Maps FirebaseAuthException codes to friendly Traditional-Chinese messages.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return '電子郵件格式不正確';
        case 'user-disabled':
          return '此帳號已被停用';
        case 'user-not-found':
          return '找不到此帳號';
        case 'wrong-password':
        case 'invalid-credential':
          return '電子郵件或密碼錯誤';
        case 'email-already-in-use':
          return '此電子郵件已被註冊';
        case 'weak-password':
          return '密碼強度不足（至少 6 個字元）';
        case 'network-request-failed':
          return '網路連線失敗，請稍後再試';
        case 'too-many-requests':
          return '嘗試次數過多，請稍後再試';
        case 'operation-not-allowed':
          return '尚未啟用電子郵件登入，請稍後再試';
        default:
          return error.message ?? '發生錯誤，請稍後再試';
      }
    }
    return '發生錯誤，請稍後再試';
  }
}
