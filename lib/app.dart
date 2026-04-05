import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_notifier.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/feed/notifiers/feed_notifier.dart';
import 'presentation/profile/notifiers/profile_notifier.dart';

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
        ChangeNotifierProvider(create: (_) => FeedNotifier(sl.feedRepo)),
        ChangeNotifierProvider(create: (_) => ProfileNotifier(sl.profileRepo)),
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
