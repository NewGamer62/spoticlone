import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../player/desktop_player_bar.dart';
import '../player/mobile_mini_player.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/lyrics_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/queue_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        // Current active content screen
        Widget activeScreen;
        switch (navState.currentTab) {
          case AppTab.home:
            activeScreen = const HomeScreen();
            break;
          case AppTab.search:
            activeScreen = const SearchScreen();
            break;
          case AppTab.library:
            activeScreen = const LibraryScreen();
            break;
          case AppTab.playlistDetail:
            activeScreen = navState.selectedPlaylist != null
                ? PlaylistDetailScreen(playlist: navState.selectedPlaylist!)
                : const HomeScreen();
            break;
          case AppTab.queue:
            activeScreen = const QueueScreen();
            break;
          case AppTab.lyrics:
            activeScreen = const LyricsScreen();
            break;
          case AppTab.settings:
            activeScreen = const SettingsScreen();
            break;
        }

        if (isDesktop) {
          // DESKTOP LAYOUT (Windows)
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Left Sidebar (Navigation & Playlists)
                      _buildDesktopSidebar(context, ref, navState),

                      // Main Content Area
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: activeScreen,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Fixed Player Bar
                const DesktopPlayerBar(),
              ],
            ),
          );
        } else {
          // MOBILE LAYOUT (Android)
          final selectedNavIndex = switch (navState.currentTab) {
            AppTab.home => 0,
            AppTab.search => 1,
            AppTab.library => 2,
            _ => 0,
          };

          return Scaffold(
            body: activeScreen,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Sticky Mini Player
                const MobileMiniPlayer(),

                // Bottom Navigation Bar
                BottomNavigationBar(
                  currentIndex: selectedNavIndex,
                  onTap: (index) {
                    if (index == 0) {
                      ref.read(navigationProvider.notifier).setTab(AppTab.home);
                    } else if (index == 1) {
                      ref.read(navigationProvider.notifier).setTab(AppTab.search);
                    } else if (index == 2) {
                      ref.read(navigationProvider.notifier).setTab(AppTab.library);
                    }
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_filled),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.library_music),
                      label: 'Your Library',
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, WidgetRef ref, NavigationState navState) {
    final library = ref.watch(libraryProvider);

    return Container(
      width: 260,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & App Name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.music_note, color: AppColors.onAccent, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SpotiClone',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Primary Navigation Links
          _buildSidebarItem(
            icon: Icons.home_filled,
            label: 'Home',
            isActive: navState.currentTab == AppTab.home,
            onTap: () => ref.read(navigationProvider.notifier).setTab(AppTab.home),
          ),
          _buildSidebarItem(
            icon: Icons.search,
            label: 'Search',
            isActive: navState.currentTab == AppTab.search,
            onTap: () => ref.read(navigationProvider.notifier).setTab(AppTab.search),
          ),
          _buildSidebarItem(
            icon: Icons.library_music,
            label: 'Your Library',
            isActive: navState.currentTab == AppTab.library,
            onTap: () => ref.read(navigationProvider.notifier).setTab(AppTab.library),
          ),

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.border, height: 1),
          ),
          const SizedBox(height: 12),

          // Pinned Playlists Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'PLAYLISTS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Playlists List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: library.playlists.length,
              itemBuilder: (ctx, i) {
                final pl = library.playlists[i];
                final isSelected = navState.currentTab == AppTab.playlistDetail &&
                    navState.selectedPlaylist?.id == pl.id;

                return InkWell(
                  onTap: () {
                    ref.read(navigationProvider.notifier).openPlaylist(pl);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pl.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? AppColors.text : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? AppColors.text : AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? AppColors.text : AppColors.textMuted,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
