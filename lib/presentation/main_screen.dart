import 'package:flutter/material.dart';
import '../core/design/app_tokens.dart';
import '../core/widgets/glass_bottom_nav.dart';
import 'feed/screens/feed_screen.dart';
import 'profile/screens/my_profile_screen.dart';
import 'profile/screens/search_screen.dart';

/// Tela principal do app com GlassBottomNav Stitch.
/// Usa IndexedStack para manter o estado de cada aba entre trocas.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    SearchScreen(),
    _MessagesPlaceholder(),
    MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Placeholder temporário enquanto a tela de mensagens não está implementada.
class _MessagesPlaceholder extends StatelessWidget {
  const _MessagesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 80, color: AppTokens.outline),
            const SizedBox(height: 16),
            Text('Mensagens',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Em breve — chat em tempo real\nentre estudantes conectados.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTokens.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
