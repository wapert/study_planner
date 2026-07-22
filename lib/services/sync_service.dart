import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/app_provider.dart';
import 'auth_service.dart';
import 'firestore_serializers.dart';

enum SyncStatus { offline, syncing, synced, error }

/// Two-way sync between the local Hive store (AppProvider) and Firestore.
///
/// Firestore layout: users/{uid}/{collection}/{docId}
/// Each doc carries `updatedAt` (client millis) + `ownerId` for last-write-wins
/// and security rules. A local `syncMeta` box tracks per-record
/// "updatedAt:contentHash" so we can detect local edits and remote-vs-local
/// freshness without echo loops.
class SyncService extends ChangeNotifier {
  final AppProvider provider;
  final AuthService auth;

  SyncService({required this.provider, required this.auth}) {
    _authSub = auth.authStateChanges().listen(_onAuthChanged);
    provider.addListener(_onLocalChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  final List<StreamSubscription> _collectionSubs = [];
  Box<String>? _meta;
  Timer? _pushDebounce;
  String? _uid;

  SyncStatus _status = SyncStatus.offline;
  SyncStatus get status => _status;
  DateTime? lastSyncedAt;
  String? lastError;

  void _setStatus(SyncStatus s, {String? error}) {
    _status = s;
    lastError = error;
    if (s == SyncStatus.synced) lastSyncedAt = DateTime.now();
    notifyListeners();
  }

  // ── Auth lifecycle ──────────────────────────────────────────────────────────

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      await _stop();
      return;
    }
    await _start(user.uid);
  }

  Future<void> _start(String uid) async {
    _uid = uid;
    _meta ??= await Hive.openBox<String>('syncMeta');
    _setStatus(SyncStatus.syncing);

    // Account-switch handling: if a *different* account previously synced on
    // this device, clear its data before pulling the new account's data.
    // If no account has synced here yet (local-only usage), keep local data
    // so it gets adopted into this account.
    final lastUid = _meta!.get('__lastUid__');
    if (lastUid != null && lastUid != uid) {
      await provider.wipeLocalData();
      await _clearMeta();
    }
    await _meta!.put('__lastUid__', uid);

    try {
      // 1. Initial pull of existing cloud data.
      await _initialPull();
      // 2. Push local records that are new or newer than cloud.
      await _pushAll();
      // 3. Attach live listeners for ongoing remote changes.
      _attachListeners();
      _setStatus(SyncStatus.synced);
    } catch (e) {
      debugPrint('Sync start error: $e');
      _setStatus(SyncStatus.error, error: e.toString());
    }
  }

  Future<void> _stop() async {
    _pushDebounce?.cancel();
    for (final s in _collectionSubs) {
      await s.cancel();
    }
    _collectionSubs.clear();
    _uid = null;
    _setStatus(SyncStatus.offline);
  }

  // ── Meta helpers ────────────────────────────────────────────────────────────

  String _metaKey(String col, String id) => '$col/$id';

  int _hashOf(Map<String, dynamic> map) => jsonEncode(map).hashCode;

  ({int updatedAt, int hash})? _metaFor(String col, String id) {
    final raw = _meta!.get(_metaKey(col, id));
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    return (updatedAt: int.parse(parts[0]), hash: int.parse(parts[1]));
  }

  Future<void> _writeMeta(
          String col, String id, int updatedAt, int hash) async =>
      _meta!.put(_metaKey(col, id), '$updatedAt:$hash');

  Future<void> _deleteMeta(String col, String id) async =>
      _meta!.delete(_metaKey(col, id));

  Future<void> _clearMeta() async {
    final keys = _meta!.keys.where((k) => k != '__lastUid__').toList();
    await _meta!.deleteAll(keys);
  }

  CollectionReference<Map<String, dynamic>> _col(String col) =>
      _db.collection('users').doc(_uid).collection(col);

  // ── Pull ────────────────────────────────────────────────────────────────────

  Future<void> _initialPull() async {
    for (final col in Collections.all) {
      final snap = await _col(col).get();
      final byId = <String, dynamic>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final remoteUpdated = (data['updatedAt'] as num?)?.toInt() ?? 0;
        final local = _metaFor(col, doc.id);
        if (local == null || remoteUpdated >= local.updatedAt) {
          final obj = fromMapFor(col, data);
          byId[doc.id] = obj;
          await _writeMeta(col, doc.id, remoteUpdated, _hashOf(data));
        }
      }
      if (byId.isNotEmpty) {
        await provider.applyRemoteBatch(col, byId);
      }
    }
  }

  void _attachListeners() {
    for (final col in Collections.all) {
      final sub = _col(col).snapshots().listen((snap) {
        _applySnapshot(col, snap);
      }, onError: (e) => debugPrint('Listener error ($col): $e'));
      _collectionSubs.add(sub);
    }
  }

  Future<void> _applySnapshot(
      String col, QuerySnapshot<Map<String, dynamic>> snap) async {
    final byId = <String, dynamic>{};
    for (final change in snap.docChanges) {
      final doc = change.doc;
      if (change.type == DocumentChangeType.removed) {
        if (_metaFor(col, doc.id) != null) {
          byId[doc.id] = null; // delete locally
          await _deleteMeta(col, doc.id);
        }
        continue;
      }
      final data = doc.data();
      if (data == null) continue;
      final remoteUpdated = (data['updatedAt'] as num?)?.toInt() ?? 0;
      final local = _metaFor(col, doc.id);
      if (local == null || remoteUpdated > local.updatedAt) {
        byId[doc.id] = fromMapFor(col, data);
        await _writeMeta(col, doc.id, remoteUpdated, _hashOf(data));
      }
    }
    if (byId.isNotEmpty) {
      await provider.applyRemoteBatch(col, byId);
    }
  }

  // ── Push ────────────────────────────────────────────────────────────────────

  void _onLocalChanged() {
    if (_uid == null || provider.suppressSync) return;
    _pushDebounce?.cancel();
    _pushDebounce = Timer(const Duration(milliseconds: 800), () {
      _pushAll();
    });
  }

  Future<void> _pushAll() async {
    if (_uid == null) return;
    try {
      _setStatus(SyncStatus.syncing);
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final col in Collections.all) {
        final records = provider.recordsFor(col);
        final localIds = <String>{};

        for (final record in records) {
          final id = provider.idOf(record);
          localIds.add(id);
          final map = toMapFor(col, record);
          final hash = _hashOf(map);
          final meta = _metaFor(col, id);
          if (meta == null || meta.hash != hash) {
            // New or locally modified → push.
            final payload = {
              ...map,
              'updatedAt': now,
              'ownerId': _uid,
            };
            await _col(col).doc(id).set(payload);
            await _writeMeta(col, id, now, _hashOf(payload));
          }
        }

        // Deletions: ids we previously synced but that are gone locally.
        final syncedIds = _meta!.keys
            .whereType<String>()
            .where((k) => k.startsWith('$col/'))
            .map((k) => k.substring(col.length + 1))
            .toList();
        for (final id in syncedIds) {
          if (!localIds.contains(id)) {
            await _col(col).doc(id).delete();
            await _deleteMeta(col, id);
          }
        }
      }
      _setStatus(SyncStatus.synced);
    } catch (e) {
      debugPrint('Push error: $e');
      _setStatus(SyncStatus.error, error: e.toString());
    }
  }

  // ── Manual controls ───────────────────────────────────────────────────────────

  Future<void> syncNow() async => _pushAll();

  @override
  void dispose() {
    _authSub?.cancel();
    provider.removeListener(_onLocalChanged);
    _pushDebounce?.cancel();
    for (final s in _collectionSubs) {
      s.cancel();
    }
    super.dispose();
  }
}
