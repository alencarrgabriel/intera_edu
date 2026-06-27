import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_notifier.dart';
import 'core/di/service_locator.dart';
import 'core/network/socket_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/feed/notifiers/feed_notifier.dart';
import 'presentation/messages/notifiers/messages_notifier.dart';
import 'presentation/profile/notifiers/profile_notifier.dart';
import 'presentation/groups/notifiers/groups_notifier.dart';
import 'presentation/groups/notifiers/group_detail_notifier.dart';
import 'presentation/stories/notifiers/stories_notifier.dart';
import 'presentation/bookmarks/notifiers/bookmarks_notifier.dart';
import 'presentation/tags/notifiers/tags_notifier.dart';
import 'presentation/suggestions/notifiers/suggestions_notifier.dart';

class InteraEduApp extends StatelessWidget {
  const InteraEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final auth = AuthNotifier(authRepo: sl.authRepo, storage: sl.storage);
          sl.apiClient.onForceLogout = auth.forceLogout;
          auth.checkSession();
          return auth;
        }),
        // Conecta/desconecta o WebSocket automaticamente conforme o
        // estado de autenticação muda. Sem isso, o chat carrega o
        // histórico via REST mas não recebe mensagens em tempo real.
        ChangeNotifierProvider<SocketService>(
          lazy: false,
          create: (ctx) {
            final socket = SocketService();
            final auth = ctx.read<AuthNotifier>();
            Future<void> sync() async {
              if (auth.isAuthenticated) {
                final token = await sl.storage.getAccessToken();
                if (token != null) socket.connect(token);
              } else {
                socket.disconnect();
              }
            }
            auth.addListener(sync);
            // Sincroniza estado inicial (caso o app já volte autenticado).
            sync();
            return socket;
          },
        ),
        ChangeNotifierProvider(create: (_) => FeedNotifier(sl.feedRepo)),
        ChangeNotifierProvider(create: (_) => ProfileNotifier(sl.profileRepo)),
        ChangeNotifierProvider(create: (_) => MessagesNotifier(sl.messagingRepo)),
        ChangeNotifierProvider(create: (_) => GroupsNotifier()),
        ChangeNotifierProvider(create: (_) => GroupDetailNotifier()),
        ChangeNotifierProvider(create: (_) => StoriesNotifier()),
        ChangeNotifierProvider(create: (_) => BookmarksNotifier()),
        ChangeNotifierProvider(create: (_) => TagsNotifier()),
        ChangeNotifierProvider(create: (_) => SuggestionsNotifier()),
      ],
      // Builder necessário para que `createRouter` acesse os providers acima.
      child: Builder(
        builder: (ctx) {
          final router = createRouter(ctx);
          return MaterialApp.router(
            title: 'InteraEdu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
