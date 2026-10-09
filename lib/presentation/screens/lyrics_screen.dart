import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/lyrics_line.dart';
import '../providers/navigation_provider.dart';
import '../providers/player_provider.dart';

class LyricsScreen extends ConsumerWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final currentTrack = player.currentTrack;

    if (currentTrack == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => ref.read(navigationProvider.notifier).setTab(AppTab.home),
          ),
        ),
        body: const Center(
          child: Text('Play a song to view lyrics', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final lyrics = LyricsLine.parseLrc(currentTrack.lyricsLrc);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentTrack.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(currentTrack.artist, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(navigationProvider.notifier).setTab(AppTab.home),
        ),
      ),
      body: lyrics.isEmpty
          ? const Center(
              child: Text(
                'No lyrics available for this song',
                style: TextStyle(color: AppColors.textMuted, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              itemCount: lyrics.length,
              itemBuilder: (ctx, i) {
                final line = lyrics[i];
                final isCurrent = player.position >= line.timestamp &&
                    (i == lyrics.length - 1 || player.position < lyrics[i + 1].timestamp);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: InkWell(
                    onTap: () {
                      ref.read(playerProvider.notifier).seek(line.timestamp);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Text(
                      line.text,
                      style: TextStyle(
                        color: isCurrent ? AppColors.accent : AppColors.textMuted,
                        fontSize: isCurrent ? 26 : 20,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
