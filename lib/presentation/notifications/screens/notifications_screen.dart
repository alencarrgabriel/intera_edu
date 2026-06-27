import 'package:flutter/material.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/widgets/app_snackbar.dart';

/// RF-35 — Central de notificações in-app.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await sl.apiClient.get(ApiEndpoints.notifications);
      setState(() {
        _items = ((res['data'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>();
        _unread = (res['unread'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await sl.apiClient.patch(ApiEndpoints.notificationsReadAll);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
    }
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'new_message' => Icons.chat_bubble_outline,
      'connection_request' => Icons.person_add_outlined,
      'connection_accepted' => Icons.handshake_outlined,
      'post_comment' => Icons.mode_comment_outlined,
      'post_reaction' => Icons.thumb_up_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: AppTokens.background,
        elevation: 0,
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style: const TextStyle(color: AppTokens.error)),
                    ),
                  ])
                : _items.isEmpty
                    ? ListView(children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 56, color: AppTokens.outlineVariant),
                              const SizedBox(height: 12),
                              Text(
                                'Você está em dia.',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quando alguém interagir com você, vai aparecer aqui.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppTokens.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ])
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 64),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          final unread = n['readAt'] == null;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: unread
                                  ? AppTokens.primaryContainer
                                  : AppTokens.surfaceContainerHigh,
                              child: Icon(
                                _iconFor(n['type']?.toString() ?? ''),
                                color: unread
                                    ? AppTokens.primary
                                    : AppTokens.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              n['title']?.toString() ?? '',
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: n['body'] != null
                                ? Text(n['body'].toString())
                                : null,
                            trailing: unread
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTokens.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              if (unread) {
                                try {
                                  await sl.apiClient.patch(
                                      ApiEndpoints.notificationRead(
                                          n['id'].toString()));
                                  await _load();
                                } catch (_) {}
                              }
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
