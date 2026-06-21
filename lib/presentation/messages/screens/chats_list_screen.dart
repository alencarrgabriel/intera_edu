import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/messages_notifier.dart';

/// Tela "Mensagens" no padrão Stitch:
/// header + título + subtítulo + busca + lista de conversas com preview,
/// timestamp relativo e LGPD no rodapé.
class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<MessagesNotifier>();
      if (notifier.chats.isEmpty && !notifier.loading) {
        notifier.load();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: _StitchTopBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createGroup),
        backgroundColor: AppTokens.primary,
        icon: const Icon(Icons.group_add_outlined, color: Colors.white),
        label: const Text('Novo grupo',
            style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<MessagesNotifier>(
        builder: (context, notifier, _) {
          final filtered = notifier.chats.where((c) {
            final memberName = c.members.isNotEmpty
                ? (c.members.first.fullName ?? '')
                : '';
            final name = c.name ?? (memberName.isEmpty ? 'Conversa' : memberName);
            return _query.isEmpty ||
                name.toLowerCase().contains(_query.toLowerCase());
          }).toList();

          return RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                // ── Título + subtítulo ────────────────────────────────────
                Text(
                  'Mensagens',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gerencie suas conexões e colaborações acadêmicas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 18),

                // ── Busca ─────────────────────────────────────────────────
                _SearchPill(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 18),

                // ── Lista ─────────────────────────────────────────────────
                if (notifier.loading && notifier.chats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (notifier.error != null)
                  _ErrorBox(message: notifier.error!, onRetry: notifier.load)
                else if (filtered.isEmpty)
                  _EmptyBox(query: _query)
                else
                  ...filtered.map((chat) {
                    final other = chat.members.isNotEmpty
                        ? chat.members.first
                        : null;
                    final memberName = other?.fullName ?? '';
                    final name = chat.name ??
                        (memberName.isEmpty ? 'Conversa' : memberName);
                    final lastMsg = chat.lastMessage;

                    return _ChatTile(
                      name: name,
                      avatarUrl: other?.avatarUrl,
                      previewSender: lastMsg != null
                          ? (lastMsg.senderName ?? '')
                          : '',
                      preview: lastMsg?.content ?? 'Sem mensagens ainda.',
                      time: lastMsg != null
                          ? _formatRelative(lastMsg.createdAt)
                          : '',
                      onTap: () => context.push('/chat/${chat.id}',
                          extra: {'name': name, 'chatId': chat.id}),
                    );
                  }),

                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'SEUS DADOS ESTÃO PROTEGIDOS SOB A LGPD.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: AppTokens.outlineVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatRelative(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'AGORA';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (now.year == d.year && now.month == d.month && now.day == d.day) {
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (DateTime(d.year, d.month, d.day) == yesterday) return 'Ontem';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}';
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _StitchTopBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu_rounded, color: AppTokens.onSurface),
      ),
      title: Text(
        'InteraEdu',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTokens.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_outlined,
              color: AppTokens.primary),
        ),
      ],
    );
  }
}

// ── Search pill ───────────────────────────────────────────────────────────────

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppTokens.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Buscar conversas…',
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat tile ─────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.name,
    required this.previewSender,
    required this.preview,
    required this.time,
    required this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final String previewSender;
  final String preview;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecent = time == 'AGORA';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(name: name, imageUrl: avatarUrl, radius: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    previewSender.isNotEmpty
                        ? '$previewSender: $preview'
                        : preview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isRecent ? FontWeight.w700 : FontWeight.w500,
                color: isRecent ? AppTokens.primary : AppTokens.onSurfaceVariant,
                letterSpacing: isRecent ? 0.6 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error ─────────────────────────────────────────────────────────────

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 56, color: AppTokens.outlineVariant),
          const SizedBox(height: 12),
          Text(
            query.isEmpty
                ? 'Sem conversas ainda'
                : 'Nada encontrado para "$query"',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Inicie uma conversa pela página de um colega.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTokens.error),
          const SizedBox(height: 8),
          Text(message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
