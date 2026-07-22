import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/share_service.dart';
import 'shared_plan_screen.dart';

const _blue = Color(0xFF1565C0);

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final share = context.read<ShareService>();
    final sync = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(title: const Text('帳號與同步'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Account card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('已登入',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(auth.email ?? '—',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Sync status ─────────────────────────────────────────────────
          _SyncStatusTile(sync: sync),
          const SizedBox(height: 24),

          // ── Share my plan ───────────────────────────────────────────────
          const _SectionLabel('分享我的計畫'),
          const SizedBox(height: 4),
          Text('輸入對方的電子郵件，對方登入後即可（唯讀）查看你的讀書計畫。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('新增分享對象'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _blue,
              side: const BorderSide(color: _blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showShareDialog(context, share),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<ViewerEntry>>(
            stream: share.myViewers(),
            builder: (context, snap) {
              final viewers = snap.data ?? [];
              if (viewers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('尚未分享給任何人',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                );
              }
              return Column(
                children: viewers
                    .map((v) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.visibility_outlined,
                              color: _blue),
                          title: Text(v.email),
                          subtitle: const Text('可唯讀查看'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => share.removeViewer(v.email),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Shared with me ──────────────────────────────────────────────
          const _SectionLabel('與我分享的計畫'),
          const SizedBox(height: 10),
          StreamBuilder<List<OwnerEntry>>(
            stream: share.sharedWithMe(),
            builder: (context, snap) {
              final owners = snap.data ?? [];
              if (owners.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('目前沒有其他人分享計畫給你',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                );
              }
              return Column(
                children: owners
                    .map((o) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: _blue,
                              child: Icon(Icons.people,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text(o.ownerEmail),
                            subtitle: const Text('點擊查看（唯讀）'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SharedPlanScreen(
                                    owner: o, share: share),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Sign out ────────────────────────────────────────────────────
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red, size: 18),
            label: const Text('登出', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('登出'),
                  content: const Text(
                      '登出後將停止同步。你的資料仍保留在雲端，下次登入可還原。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消')),
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('登出')),
                  ],
                ),
              );
              if (confirmed == true) {
                await auth.signOut();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, ShareService share) {
    final ctrl = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新增分享對象'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '對方電子郵件',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _blue),
              onPressed: () async {
                try {
                  await share.shareWith(ctrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setState(() => error =
                      e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('分享'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
}

class _SyncStatusTile extends StatelessWidget {
  final SyncService sync;
  const _SyncStatusTile({required this.sync});

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (sync.status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_outlined;
        color = Colors.green;
        label = sync.lastSyncedAt != null
            ? '已同步 · ${_time(sync.lastSyncedAt!)}'
            : '已同步';
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync_outlined;
        color = _blue;
        label = '同步中…';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off_outlined;
        color = Colors.orange;
        label = '同步發生問題';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_outlined;
        color = Colors.grey;
        label = '未同步';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          TextButton(
            onPressed: sync.status == SyncStatus.syncing
                ? null
                : () => sync.syncNow(),
            child: const Text('立即同步'),
          ),
        ],
      ),
    );
  }

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
