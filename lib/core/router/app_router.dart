import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/otp_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/feed/screens/create_post_screen.dart';
import '../../presentation/main_screen.dart';
import '../../presentation/admin/screens/admin_screen.dart';
import '../../presentation/notifications/screens/notifications_screen.dart';
import '../../presentation/settings/screens/settings_screen.dart';
import '../../presentation/settings/screens/server_setup_screen.dart';
import '../config/server_config.dart';
import '../../presentation/messages/screens/chat_room_screen.dart';
import '../../presentation/messages/screens/create_group_screen.dart';
import '../../presentation/onboarding/screens/profile_setup_screen.dart';
import '../../presentation/onboarding/screens/welcome_screen.dart';
import '../../presentation/profile/screens/connections_screen.dart';
import '../../presentation/profile/screens/edit_profile_screen.dart';
import '../../presentation/profile/screens/user_profile_screen.dart';
import '../../presentation/profile/screens/handle_redirect_screen.dart';
import '../../presentation/groups/screens/groups_list_screen.dart';
import '../../presentation/groups/screens/group_detail_screen.dart';
import '../../presentation/bookmarks/screens/bookmarks_screen.dart';
import '../../presentation/tags/screens/tag_detail_screen.dart';
import '../../presentation/stories/screens/story_viewer_screen.dart';
import '../../presentation/stories/screens/create_story_screen.dart';
import '../../presentation/suggestions/screens/suggestions_screen.dart';
import '../auth/auth_notifier.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/story.dart';

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
  static const forgotPassword = '/forgot-password';
  static const profileSetup = '/profile-setup';
  static const main = '/';

  // Rotas filhas de '/' — use como strings completas
  static const createPost = '/create-post';
  static const editProfile = '/edit-profile';
  static const connections = '/connections';
  static const notifications = '/notifications';
  static const createGroup = '/create-group';
  static const settings = '/settings';
  static const admin = '/admin';

  static String userProfile(String userId) => '/user/$userId';
  static String chatRoom(String chatId) => '/chat/$chatId';

  // Novas
  static const groups = '/groups';
  static const bookmarks = '/bookmarks';
  static const suggestions = '/suggestions';
  static const createStory = '/create-story';
  static const serverSetup = '/server-setup';
  static const initialServerSetup = '/welcome-server-setup';
  static String groupDetail(String groupId) => '/group/$groupId';
  static String tagDetail(String slug) => '/tag/$slug';
  static String storyViewer(int initialIndex) => '/stories/view';
}

/// Cria o GoRouter com auth guard baseado no `AuthNotifier`.
/// O `refreshListenable` garante que redirect() é reavaliado a cada
/// mudança de status de autenticação.
GoRouter createRouter(BuildContext context) {
  final auth = Provider.of<AuthNotifier>(context, listen: false);

  return GoRouter(
    refreshListenable: auth,
    initialLocation: ServerConfig.instance.needsSetup
        ? AppRoutes.initialServerSetup
        : AppRoutes.main,
    redirect: (ctx, state) {
      final status = auth.status;
      final loc = state.matchedLocation;

      // Bloqueia tudo até o servidor ser configurado.
      if (ServerConfig.instance.needsSetup &&
          loc != AppRoutes.initialServerSetup) {
        return AppRoutes.initialServerSetup;
      }
      if (loc == AppRoutes.initialServerSetup) return null;

      final authPaths = {
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.otp,
        AppRoutes.forgotPassword,
        AppRoutes.profileSetup,
      };
      final isAuthPath = authPaths.contains(loc);

      if (loc == AppRoutes.profileSetup) return null;

      if (status == AuthStatus.loading) return null;
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
            pageBuilder: (ctx, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final groupId = extra?['group_id'] as String?;
              return _slideTransition(
                  context: ctx,
                  state: state,
                  child: CreatePostScreen(groupId: groupId));
            },
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
            path: 'notifications',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const NotificationsScreen()),
          ),
          GoRoute(
            path: 'create-group',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const CreateGroupScreen()),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const SettingsScreen()),
          ),
          GoRoute(
            path: 'server-setup',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const ServerSetupScreen()),
          ),
          GoRoute(
            path: 'admin',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const AdminScreen()),
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
            path: 'u/:handle',
            pageBuilder: (ctx, state) {
              final handle = state.pathParameters['handle']!;
              return _slideTransition(
                  context: ctx,
                  state: state,
                  child: HandleRedirectScreen(handle: handle));
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
          GoRoute(
            path: 'groups',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const GroupsListScreen()),
          ),
          GoRoute(
            path: 'group/:groupId',
            pageBuilder: (ctx, state) {
              final id = state.pathParameters['groupId']!;
              return _slideTransition(
                  context: ctx, state: state, child: GroupDetailScreen(groupId: id));
            },
          ),
          GoRoute(
            path: 'bookmarks',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const BookmarksScreen()),
          ),
          GoRoute(
            path: 'tag/:slug',
            pageBuilder: (ctx, state) {
              final slug = state.pathParameters['slug']!;
              return _slideTransition(
                  context: ctx, state: state, child: TagDetailScreen(slug: slug));
            },
          ),
          GoRoute(
            path: 'stories/view',
            pageBuilder: (ctx, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final groups = (extra?['groups'] as List<dynamic>?)?.cast<StoryGroup>() ?? const [];
              final initial = (extra?['initialIndex'] as int?) ?? 0;
              return _slideTransition(
                  context: ctx,
                  state: state,
                  child: StoryViewerScreen(groups: groups, initialIndex: initial));
            },
          ),
          GoRoute(
            path: 'create-story',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const CreateStoryScreen()),
          ),
          GoRoute(
            path: 'suggestions',
            pageBuilder: (ctx, state) => _slideTransition(
                context: ctx, state: state, child: const SuggestionsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.initialServerSetup,
        builder: (_, __) => const ServerSetupScreen(isInitialSetup: true),
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
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
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
          // No web o go_router pode restaurar `extra` como _JsonMap
          // (Map<String, dynamic>) em vez do literal Map<String, String>.
          final extra = (state.extra as Map?)?.cast<String, dynamic>();
          if (extra == null) {
            // Navegação direta sem dados — volta para register
            return const RegisterScreen();
          }
          return ProfileSetupScreen(
            temporaryToken: extra['token'] as String,
            email: extra['email'] as String,
          );
        },
      ),
    ],
  );
}
