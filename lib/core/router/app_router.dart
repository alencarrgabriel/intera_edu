import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/otp_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/feed/screens/create_post_screen.dart';
import '../../presentation/main_screen.dart';
import '../../presentation/messages/screens/chat_room_screen.dart';
import '../../presentation/onboarding/screens/profile_setup_screen.dart';
import '../../presentation/onboarding/screens/welcome_screen.dart';
import '../../presentation/profile/screens/connections_screen.dart';
import '../../presentation/profile/screens/edit_profile_screen.dart';
import '../../presentation/profile/screens/user_profile_screen.dart';
import '../auth/auth_notifier.dart';
import '../../domain/entities/user.dart';

/// Transição padrão: fade + slide suave (250ms).
CustomTransitionPage<T> _slideTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (ctx, animation, secondaryAnimation, c) {
      final slide = Tween(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: c),
      );
    },
  );
}

/// Rotas nomeadas — use estas constantes em vez de strings avulsas.
abstract class AppRoutes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const profileSetup = '/profile-setup';
  static const main = '/';

  // Rotas filhas de '/' — use como strings completas
  static const createPost = '/create-post';
  static const editProfile = '/edit-profile';
  static const connections = '/connections';

  static String userProfile(String userId) => '/user/$userId';
  static String chatRoom(String chatId) => '/chat/$chatId';
}

/// Cria o GoRouter com auth guard baseado no `AuthNotifier`.
/// O `refreshListenable` garante que redirect() é reavaliado a cada
/// mudança de status de autenticação.
GoRouter createRouter(BuildContext context) {
  final auth = Provider.of<AuthNotifier>(context, listen: false);

  return GoRouter(
    refreshListenable: auth,
    initialLocation: AppRoutes.main,
    redirect: (ctx, state) {
      final status = auth.status;
      final loc = state.matchedLocation;

      final authPaths = {
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.otp,
        AppRoutes.profileSetup,
      };
      final isAuthPath = authPaths.contains(loc);

      // Permite /profile-setup mesmo autenticado (etapa pós-registro)
      if (loc == AppRoutes.profileSetup) return null;

      if (status == AuthStatus.loading) return null; // aguarda
      if (status == AuthStatus.unauthenticated && !isAuthPath) {
        return AppRoutes.welcome;
      }
      if (status == AuthStatus.authenticated && isAuthPath) {
        return AppRoutes.main;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.main,
        builder: (_, __) => const MainScreen(),
        routes: [
          GoRoute(
            path: 'create-post',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const CreatePostScreen()),
          ),
          GoRoute(
            path: 'edit-profile',
            pageBuilder: (ctx, state) {
              final profile = state.extra as User;
              return _slideTransition(
                  context: ctx,
                  state: state,
                  child: EditProfileScreen(profile: profile));
            },
          ),
          GoRoute(
            path: 'connections',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const ConnectionsScreen()),
          ),
          GoRoute(
            path: 'user/:userId',
            pageBuilder: (ctx, state) {
              final userId = state.pathParameters['userId']!;
              final name = state.extra as String?;
              return _slideTransition(
                  context: ctx,
                  state: state,
                  child:
                      UserProfileScreen(userId: userId, initialName: name));
            },
          ),
          GoRoute(
            path: 'chat/:chatId',
            pageBuilder: (ctx, state) {
              final chatId = state.pathParameters['chatId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return _slideTransition(
                  context: ctx,
                  state: state,
                  child: ChatRoomScreen(
                    chatId: chatId,
                    chatName: extra?['name'] as String?,
                  ));
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) {
          final email = state.extra as String;
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, state) {
          final extra = state.extra as Map<String, String>?;
          if (extra == null) {
            // Navegação direta sem dados — volta para register
            return const RegisterScreen();
          }
          return ProfileSetupScreen(
            temporaryToken: extra['token']!,
            email: extra['email']!,
          );
        },
      ),
    ],
  );
}
