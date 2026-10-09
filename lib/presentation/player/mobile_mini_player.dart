import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import 'fullscreen_player_modal.dart';

class MobileMiniPlayer extends ConsumerWidget {
  const MobileMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final library = ref.watch(libraryProvider);
    final currentTrack = player.currentTrack;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    final isLiked = library.likedTrackIds.contains(currentTrack.id);
    final progress = player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (ctx) => const FullscreenPlayerModal(),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini Player Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        currentTrack.coverUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.surface,
                          child: const Icon(Icons.music_note, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrack.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            currentTrack.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Like Button
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? AppColors.accent : AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(libraryProvider.notifier).toggleLike(currentTrack);
                      },
                    ),

                    // Play/Pause Button
                    IconButton(
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.text,
                        size: 28,
                      ),
                      onPressed: () {
                        ref.read(playerProvider.notifier).togglePlayPause();
                      },
                    ),
                  ],
                ),
              ),

              // Thin Progress Bar
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
