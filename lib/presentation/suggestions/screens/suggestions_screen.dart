import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/suggestions_notifier.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuggestionsNotifier>().load();
    });
  }

  Future<void> _connect(String userId, SuggestionsNotifier n) async {
    try {
      await sl.connRepo.sendRequest(userId);
      n.dismiss(userId);
      if (!mounted) return;
      AppSnackbar.success(context, 'Solicitação enviada!');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: AppTokens.background,
        elevation: 0,
        title: const Text('Pessoas pra conhecer',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Consumer<SuggestionsNotifier>(
        builder: (_, n, __) {
          if (n.loading && n.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (n.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sem sugestões no momento.',
                  style: TextStyle(color: AppTokens.onSurfaceVariant),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: n.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: n.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = n.items[i];
                return Card(
                  elevation: 0,
                  color: AppTokens.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    side: BorderSide(color: AppTokens.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        UserAvatar(
                            name: s.fullName,
                            imageUrl: s.avatarUrl,
                            radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                s.reason,
                                style: TextStyle(
                                    color: AppTokens.onSurfaceVariant,
                                    fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_outline),
                          tooltip: 'Ver perfil',
                          onPressed: () => context.push(
                              AppRoutes.userProfile(s.userId),
                              extra: s.fullName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add_outlined),
                          tooltip: 'Conectar',
                          onPressed: () => _connect(s.userId, n),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
