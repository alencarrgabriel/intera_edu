import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stitch_skeleton.dart';
import '../../shared/user_avatar.dart';
import '../../shared/relative_time_text.dart';
import '../notifiers/messages_notifier.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTheme.glassAppBar(
        context: context,
        title: const Text('Mensagens'),
        actions: [
          Consumer<MessagesNotifier>(
            builder: (_, n, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: n.loading ? null : n.load,
              tooltip: 'Atualizar',
            ),
          ),
        ],
      ),
      body: Consumer<MessagesNotifier>(
        builder: (context, notifier, _) {
          if (notifier.loading) {
            return _buildSkeleton();
          }
          if (notifier.error != null) {
            return SafeArea(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 48, color: AppTokens.error),
                  const SizedBox(height: 12),
                  Text(notifier.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: notifier.load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ]),
              ),
            );
          }
          if (notifier.chats.isEmpty) {
            return SafeArea(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: AppTokens.outline),
                  const SizedBox(height: 16),
                  Text('Nenhuma conversa ainda.',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Conecte-se com outros estudantes e\ninicie uma conversa.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTokens.onSurfaceVariant),
                  ),
                ]),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top + kToolbarHeight + 8, 0, 24),
              itemCount: notifier.chats.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (ctx, i) {
                final chat = notifier.chats[i];
                final other = chat.members.isNotEmpty ? chat.members.first : null;
                final name = chat.name ?? other?.fullName ?? 'Conversa';
                final avatar = other?.avatarUrl;
                final lastMsg = chat.lastMessage;

                return ListTile(
                  leading: UserAvatar(name: name, imageUrl: avatar, radius: 24),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: lastMsg != null
                      ? Text(lastMsg.content,
                          maxLines: 1, overflow: TextOverflow.ellipsis)
                      : Text('Sem mensagens ainda.',
                          style: TextStyle(color: AppTokens.onSurfaceVariant)),
                  trailing: lastMsg != null
                      ? RelativeTimeText(date: lastMsg.createdAt, compact: true)
                      : null,
                  onTap: () => context.push('/chat/${chat.id}',
                      extra: {'name': name, 'chatId': chat.id}),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return SafeArea(
      child: StitchSkeleton(
        child: ListView.separated(
          padding: const EdgeInsets.only(top: kToolbarHeight + 16),
          itemCount: 6,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (_, __) => ListTile(
            leading: const SkeletonBox(width: 48, height: 48, shape: BoxShape.circle),
            title: const SkeletonBox(width: 140, height: 14),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: const SkeletonBox(width: 200, height: 12),
            ),
          ),
        ),
      ),
    );
  }
}
