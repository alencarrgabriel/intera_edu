import 'package:flutter/material.dart';
import '../core/widgets/glass_bottom_nav.dart';
import 'feed/screens/feed_screen.dart';
import 'messages/screens/chats_list_screen.dart';
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
    ChatsListScreen(),
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

