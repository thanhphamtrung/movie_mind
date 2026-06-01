import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class MainLayoutPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutPage({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Expanded(child: navigationShell),
          CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => _onTap(context, index),
            backgroundColor: AppColors.background.withValues(alpha: 0.8),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.textMuted,
            border: Border(
              top: BorderSide(
                color: AppColors.glassBorder.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.compass),
                activeIcon: Icon(CupertinoIcons.compass_fill),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble),
                activeIcon: Icon(CupertinoIcons.chat_bubble_fill),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.bookmark),
                activeIcon: Icon(CupertinoIcons.bookmark_solid),
                label: 'Watchlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                activeIcon: Icon(CupertinoIcons.person_solid),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

