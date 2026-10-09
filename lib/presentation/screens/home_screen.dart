import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/music_catalog.dart';
import '../components/media_card.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final playlists = library.playlists;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // App Bar / Greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
                        onPressed: () {
                          ref.read(navigationProvider.notifier).setTab(AppTab.settings);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 6 Quick-Access Tiles
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                mainAxisExtent: 64,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final pl = playlists[i % playlists.length];
                  return Material(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () {
                        ref.read(navigationProvider.notifier).openPlaylist(pl);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                            child: Image.network(
                              pl.coverUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.surfaceHighlight,
                                child: const Icon(Icons.music_note, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pl.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: AppColors.accent, size: 36),
                            onPressed: () {
                              if (pl.tracks.isNotEmpty) {
                                ref.read(playerProvider.notifier).playTrack(
                                      pl.tracks.first,
                                      newQueue: pl.tracks,
                                    );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  );
                },
                childCount: playlists.length.clamp(0, 6),
              ),
            ),
          ),

          // Section 1: Made For You
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Made For You',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(navigationProvider.notifier).setTab(AppTab.library);
                    },
                    child: const Text('Show all', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200
                    ? 5
                    : (MediaQuery.of(context).size.width > 800 ? 4 : 2),
                mainAxisExtent: 260,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final pl = playlists[i % playlists.length];
                  return MediaCard(
                    title: pl.title,
                    subtitle: pl.description,
                    imageUrl: pl.coverUrl,
                    onTap: () {
                      ref.read(navigationProvider.notifier).openPlaylist(pl);
                    },
                    onPlay: () {
                      if (pl.tracks.isNotEmpty) {
                        ref.read(playerProvider.notifier).playTrack(
                              pl.tracks.first,
                              newQueue: pl.tracks,
                            );
                      }
                    },
                  );
                },
                childCount: playlists.length,
              ),
            ),
          ),

          // Section 2: Recommended Tracks
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                'Popular Today',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200
                    ? 5
                    : (MediaQuery.of(context).size.width > 800 ? 4 : 2),
                mainAxisExtent: 260,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final track = MusicCatalog.allTracks[i % MusicCatalog.allTracks.length];
                  return MediaCard(
                    title: track.title,
                    subtitle: track.artist,
                    imageUrl: track.coverUrl,
                    onTap: () {
                      ref.read(playerProvider.notifier).playTrack(
                            track,
                            newQueue: MusicCatalog.allTracks,
                          );
                    },
                    onPlay: () {
                      ref.read(playerProvider.notifier).playTrack(
                            track,
                            newQueue: MusicCatalog.allTracks,
                          );
                    },
                  );
                },
                childCount: MusicCatalog.allTracks.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
