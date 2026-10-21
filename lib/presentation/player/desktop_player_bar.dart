import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/player_provider.dart';

class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final library = ref.watch(libraryProvider);
    final currentTrack = player.currentTrack;

    if (currentTrack == null) {
      return Container(
        height: 88,
        color: AppColors.surface,
        alignment: Alignment.center,
        child: const Text(
          'Select a track to start listening',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    final isLiked = library.likedTrackIds.contains(currentTrack.id);

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Left: Track Info & Like
          SizedBox(
            width: 260,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    currentTrack.coverUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.music_note, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTrack.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentTrack.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
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
              ],
            ),
          ),

          // Center: Player Controls & Scrubber Slider
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: player.isShuffle ? AppColors.accent : AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
                    ),
                    const SizedBox(width: 12),
                    // Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: AppColors.textMuted, size: 24),
                      onPressed: () => ref.read(playerProvider.notifier).previous(),
                    ),
                    const SizedBox(width: 12),
                    // Play / Pause Circle
                    Material(
                      color: AppColors.text,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => ref.read(playerProvider.notifier).togglePlayPause(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.onAccent,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: AppColors.textMuted, size: 24),
                      onPressed: () => ref.read(playerProvider.notifier).next(),
                    ),
                    const SizedBox(width: 12),
                    // Repeat
                    IconButton(
                      icon: Icon(
                        player.repeatMode == RepeatMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: player.repeatMode != RepeatMode.off
                            ? AppColors.accent
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).cycleRepeatMode(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(player.position),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        ),
                        child: Slider(
                          value: player.duration.inMilliseconds > 0
                              ? (player.position.inMilliseconds / player.duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: (val) {
                            final target = Duration(
                              milliseconds: (val * player.duration.inMilliseconds).toInt(),
                            );
                            ref.read(playerProvider.notifier).seek(target);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(player.duration),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Lyrics, Queue & Volume
          SizedBox(
            width: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Lyrics
                IconButton(
                  tooltip: 'Lyrics',
                  icon: const Icon(Icons.mic_none, color: AppColors.textMuted, size: 20),
                  onPressed: () {
                    ref.read(navigationProvider.notifier).setTab(AppTab.lyrics);
                  },
                ),
                // Queue
                IconButton(
                  tooltip: 'Queue',
                  icon: const Icon(Icons.queue_music, color: AppColors.textMuted, size: 20),
                  onPressed: () {
                    ref.read(navigationProvider.notifier).setTab(AppTab.queue);
                  },
                ),
                // Volume
                Icon(
                  player.volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 90,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    ),
                    child: Slider(
                      value: player.volume,
                      onChanged: (val) {
                        ref.read(playerProvider.notifier).setVolume(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
