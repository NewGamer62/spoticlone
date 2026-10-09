import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/playlist.dart';
import '../components/track_tile.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/player_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  String _formatTotalDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    // Find updated playlist instance in state if available
    final currentPlaylist = library.playlists.firstWhere(
      (p) => p.id == playlist.id,
      orElse: () => playlist,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header with large cover, title, description
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.bg,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.text),
                    onPressed: () {
                      ref.read(navigationProvider.notifier).setTab(AppTab.home);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Responsive Header Layout
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildCover(currentPlaylist),
                                const SizedBox(width: 24),
                                Expanded(child: _buildDetails(currentPlaylist)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(child: _buildCover(currentPlaylist, size: 180)),
                                const SizedBox(height: 16),
                                _buildDetails(currentPlaylist),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Play/Shuffle Action Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Material(
                    color: AppColors.accent,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (currentPlaylist.tracks.isNotEmpty) {
                          ref.read(playerProvider.notifier).playTrack(
                                currentPlaylist.tracks.first,
                                newQueue: currentPlaylist.tracks,
                              );
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.play_arrow, color: AppColors.onAccent, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    tooltip: 'Shuffle',
                    icon: const Icon(Icons.shuffle, color: AppColors.textMuted, size: 28),
                    onPressed: () {
                      ref.read(playerProvider.notifier).toggleShuffle();
                      if (currentPlaylist.tracks.isNotEmpty) {
                        ref.read(playerProvider.notifier).playTrack(
                              currentPlaylist.tracks.first,
                              newQueue: currentPlaylist.tracks,
                            );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  // Premium Download All button
                  IconButton(
                    tooltip: 'Download playlist (Offline mode)',
                    icon: const Icon(Icons.arrow_circle_down, color: AppColors.textMuted, size: 28),
                    onPressed: () {
                      for (final tr in currentPlaylist.tracks) {
                        ref.read(libraryProvider.notifier).toggleDownload(tr);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading playlist tracks for offline listening...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Tracks List Table
          if (currentPlaylist.tracks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No tracks in this playlist yet',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final track = currentPlaylist.tracks[i];
                    return TrackTile(
                      track: track,
                      index: i + 1,
                      queueContext: currentPlaylist.tracks,
                      onRemove: currentPlaylist.isCustom
                          ? () {
                              ref.read(libraryProvider.notifier).removeTrackFromPlaylist(
                                    currentPlaylist.id,
                                    track.id,
                                  );
                            }
                          : null,
                    );
                  },
                  childCount: currentPlaylist.tracks.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCover(Playlist pl, {double size = 200}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        pl.coverUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.surfaceHighlight,
          child: const Icon(Icons.music_note, color: AppColors.textMuted, size: 60),
        ),
      ),
    );
  }

  Widget _buildDetails(Playlist pl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLAYLIST',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pl.title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (pl.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            pl.description,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '${pl.tracks.length} songs • ${_formatTotalDuration(pl.totalDuration)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}
