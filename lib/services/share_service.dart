import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'firestore_serializers.dart';

class ViewerEntry {
  final String email;
  final DateTime? addedAt;
  ViewerEntry(this.email, this.addedAt);
}

class OwnerEntry {
  final String ownerUid;
  final String ownerEmail;
  OwnerEntry(this.ownerUid, this.ownerEmail);
}

/// Sharing: an owner grants read-only access to their whole plan by email.
///
/// Two docs per grant:
///   users/{ownerUid}/viewers/{viewerEmail}  → enforces read access (rules)
///   shares/{viewerEmail}/from/{ownerUid}     → discovery index for the viewer
class ShareService {
  final AuthService auth;
  ShareService(this.auth);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _norm(String email) => email.trim().toLowerCase();

  // ── Owner side ──────────────────────────────────────────────────────────────

  Future<void> shareWith(String rawEmail) async {
    final uid = auth.uid;
    final myEmail = auth.email;
    if (uid == null || myEmail == null) throw Exception('尚未登入');
    final viewer = _norm(rawEmail);
    if (viewer.isEmpty || !viewer.contains('@')) {
      throw Exception('電子郵件格式不正確');
    }
    if (viewer == myEmail.toLowerCase()) {
      throw Exception('不能分享給自己');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .collection('users')
        .doc(uid)
        .collection('viewers')
        .doc(viewer)
        .set({'ownerEmail': myEmail, 'addedAt': now});
    await _db
        .collection('shares')
        .doc(viewer)
        .collection('from')
        .doc(uid)
        .set({'ownerEmail': myEmail, 'addedAt': now});
  }

  Future<void> removeViewer(String rawEmail) async {
    final uid = auth.uid;
    if (uid == null) return;
    final viewer = _norm(rawEmail);
    await _db
        .collection('users')
        .doc(uid)
        .collection('viewers')
        .doc(viewer)
        .delete();
    await _db
        .collection('shares')
        .doc(viewer)
        .collection('from')
        .doc(uid)
        .delete();
  }

  Stream<List<ViewerEntry>> myViewers() {
    final uid = auth.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('viewers')
        .snapshots()
        .map((s) => s.docs.map((d) {
              final at = (d.data()['addedAt'] as num?)?.toInt();
              return ViewerEntry(
                  d.id,
                  at == null
                      ? null
                      : DateTime.fromMillisecondsSinceEpoch(at));
            }).toList());
  }

  // ── Viewer side ─────────────────────────────────────────────────────────────

  Stream<List<OwnerEntry>> sharedWithMe() {
    final myEmail = auth.email;
    if (myEmail == null) return const Stream.empty();
    return _db
        .collection('shares')
        .doc(myEmail.toLowerCase())
        .collection('from')
        .snapshots()
        .map((s) => s.docs
            .map((d) => OwnerEntry(
                d.id, (d.data()['ownerEmail'] as String?) ?? d.id))
            .toList());
  }

  /// Read another user's plan (read-only). Returns collection → list of records.
  Future<Map<String, List<dynamic>>> loadOwnerData(String ownerUid) async {
    final result = <String, List<dynamic>>{};
    for (final col in Collections.all) {
      final snap =
          await _db.collection('users').doc(ownerUid).collection(col).get();
      result[col] =
          snap.docs.map((d) => fromMapFor(col, d.data())).toList();
    }
    return result;
  }
}
