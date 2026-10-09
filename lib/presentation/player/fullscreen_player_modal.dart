import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/lyrics_line.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';

class FullscreenPlayerModal extends ConsumerStatefulWidget {
  const FullscreenPlayerModal({super.key});

  @override
  ConsumerState<FullscreenPlayerModal> createState() => _FullscreenPlayerModalState();
}

class _FullscreenPlayerModalState extends ConsumerState<FullscreenPlayerModal> {
  bool _showLyrics = false;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final library = ref.watch(libraryProvider);
    final currentTrack = player.currentTrack;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    final isLiked = library.likedTrackIds.contains(currentTrack.id);
    final lyrics = LyricsLine.parseLrc(currentTrack.lyricsLrc);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Header: Chevron down and Context
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    children: [
                      const Text(
                        'PLAYING FROM PLAYLIST',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentTrack.album,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _showLyrics ? Icons.music_note : Icons.mic,
                      color: _showLyrics ? AppColors.accent : AppColors.text,
                    ),
                    onPressed: () => setState(() => _showLyrics = !_showLyrics),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content: Artwork OR Lyrics
              Expanded(
                child: _showLyrics
                    ? (lyrics.isEmpty
                        ? const Center(
                            child: Text(
                              'No lyrics available for this song',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: lyrics.length,
                            itemBuilder: (ctx, i) {
                              final line = lyrics[i];
                              final isCurrent = player.position >= line.timestamp &&
                                  (i == lyrics.length - 1 || player.position < lyrics[i + 1].timestamp);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  line.text,
                                  style: TextStyle(
                                    color: isCurrent ? AppColors.accent : AppColors.textMuted,
                                    fontSize: isCurrent ? 24 : 18,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ))
                    : Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              currentTrack.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceElevated,
                                child: const Icon(Icons.music_note, color: AppColors.textMuted, size: 80),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Title, Artist and Like Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentTrack.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.accent : AppColors.text,
                      size: 28,
                    ),
                    onPressed: () {
                      ref.read(libraryProvider.notifier).toggleLike(currentTrack);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrubber
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(player.position), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Text(_formatDuration(player.duration), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: player.isShuffle ? AppColors.accent : AppColors.textMuted,
                      size: 26,
                    ),
                    onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: AppColors.text, size: 36),
                    onPressed: () => ref.read(playerProvider.notifier).previous(),
                  ),
                  Material(
                    color: AppColors.text,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => ref.read(playerProvider.notifier).togglePlayPause(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppColors.onAccent,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: AppColors.text, size: 36),
                    onPressed: () => ref.read(playerProvider.notifier).next(),
                  ),
                  IconButton(
                    icon: Icon(
                      player.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                      color: player.repeatMode != RepeatMode.off ? AppColors.accent : AppColors.textMuted,
                      size: 26,
                    ),
                    onPressed: () => ref.read(playerProvider.notifier).cycleRepeatMode(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
