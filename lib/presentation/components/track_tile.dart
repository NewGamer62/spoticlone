import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';

class TrackTile extends ConsumerStatefulWidget {
  final Track track;
  final int? index;
  final List<Track>? queueContext;
  final VoidCallback? onRemove;

  const TrackTile({
    super.key,
    required this.track,
    this.index,
    this.queueContext,
    this.onRemove,
  });

  @override
  ConsumerState<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends ConsumerState<TrackTile> {
  bool _isHovered = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final libraryState = ref.watch(libraryProvider);
    final isCurrentTrack = playerState.currentTrack?.id == widget.track.id;
    final isPlaying = isCurrentTrack && playerState.isPlaying;
    final isLiked = libraryState.likedTrackIds.contains(widget.track.id);
    final isDownloaded = libraryState.downloadedPaths.containsKey(widget.track.id);
    final isDownloading = libraryState.downloadingTrackIds.contains(widget.track.id);

    final trackWithInfo = libraryState.decorateTrack(widget.track);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () {
          ref.read(playerProvider.notifier).playTrack(
                trackWithInfo,
                newQueue: widget.queueContext?.map((t) => libraryState.decorateTrack(t)).toList(),
              );
        },
        borderRadius: BorderRadius.circular(4),
        hoverColor: AppColors.surfaceElevated,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentTrack ? AppColors.surfaceHighlight.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Index or Play/Speaker icon
              if (widget.index != null)
                SizedBox(
                  width: 32,
                  child: isCurrentTrack
                      ? Icon(
                          isPlaying ? Icons.volume_up : Icons.pause,
                          color: AppColors.accent,
                          size: 18,
                        )
                      : (_isHovered
                          ? const Icon(Icons.play_arrow, color: AppColors.text, size: 18)
                          : Text(
                              '${widget.index}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            )),
                ),

              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  widget.track.coverUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    color: AppColors.surfaceElevated,
                    child: const Icon(Icons.music_note, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Artist, and Offline Downloaded badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentTrack ? AppColors.accent : AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isDownloaded) ...[
                          const Icon(Icons.arrow_circle_down, color: AppColors.accent, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            widget.track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Album (Hidden on narrow screens)
              if (MediaQuery.of(context).size.width > 600)
                Expanded(
                  child: Text(
                    widget.track.album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),

              // Download / Offline Icon
              if (isDownloading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                )
              else
                IconButton(
                  tooltip: isDownloaded ? 'Downloaded (Offline ready)' : 'Download for offline listening',
                  icon: Icon(
                    isDownloaded ? Icons.arrow_circle_down : Icons.arrow_circle_down_outlined,
                    color: isDownloaded ? AppColors.accent : (_isHovered ? AppColors.textMuted : Colors.transparent),
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(libraryProvider.notifier).toggleDownload(widget.track);
                  },
                ),

              // Like Heart Button
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.accent : AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(libraryProvider.notifier).toggleLike(widget.track);
                },
              ),

              // Duration
              Text(
                _formatDuration(widget.track.duration),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),

              // Options Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
                color: AppColors.surfaceElevated,
                onSelected: (val) {
                  if (val == 'add_queue') {
                    ref.read(playerProvider.notifier).addToQueue(trackWithInfo);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to queue: ${widget.track.title}')),
                    );
                  } else if (val == 'download') {
                    ref.read(libraryProvider.notifier).toggleDownload(widget.track);
                  } else if (val == 'remove' && widget.onRemove != null) {
                    widget.onRemove!();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'add_queue',
                    child: Text('Add to queue', style: TextStyle(color: AppColors.text)),
                  ),
                  PopupMenuItem(
                    value: 'download',
                    child: Text(
                      isDownloaded ? 'Remove from downloads' : 'Download for offline',
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ),
                  if (widget.onRemove != null)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove', style: TextStyle(color: AppColors.danger)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
