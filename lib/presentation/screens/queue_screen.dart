import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../components/track_tile.dart';
import '../providers/navigation_provider.dart';
import '../providers/player_provider.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final currentTrack = player.currentTrack;
    final queue = player.queue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Play Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(navigationProvider.notifier).setTab(AppTab.home);
          },
        ),
        actions: [
          if (queue.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(playerProvider.notifier).clearQueue();
              },
              child: const Text('Clear Queue', style: TextStyle(color: AppColors.textMuted)),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Currently Playing
          if (currentTrack != null) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Now Playing',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TrackTile(track: currentTrack),
              ),
            ),
          ],

          // Next In Queue
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Next Up',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (queue.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'The queue is empty',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final track = queue[i];
                    return TrackTile(
                      track: track,
                      index: i + 1,
                      queueContext: queue,
                      onRemove: () {
                        ref.read(playerProvider.notifier).removeFromQueue(i);
                      },
                    );
                  },
                  childCount: queue.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
