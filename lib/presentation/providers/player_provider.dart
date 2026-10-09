import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../../data/audio/audio_player_service.dart';
import '../../domain/models/track.dart';

enum RepeatMode { off, all, one }

class PlayerStateData {
  final Track? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final List<Track> queue;
  final int queueIndex;

  const PlayerStateData({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.off,
    this.queue = const [],
    this.queueIndex = 0,
  });

  PlayerStateData copyWith({
    Track? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isShuffle,
    RepeatMode? repeatMode,
    List<Track>? queue,
    int? queueIndex,
  }) {
    return PlayerStateData(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
    );
  }
}

final audioServiceSingleton = AudioPlayerService();

class PlayerNotifier extends Notifier<PlayerStateData> {
  late final AudioPlayerService _audioService;

  @override
  PlayerStateData build() {
    _audioService = audioServiceSingleton;
    _initSubscriptions();
    return const PlayerStateData();
  }

  void _initSubscriptions() {
    _audioService.playerStateStream.listen((jaState) {
      final isPlaying = jaState.playing;
      final isBuffering = jaState.processingState == ja.ProcessingState.buffering ||
          jaState.processingState == ja.ProcessingState.loading;
      final isCompleted = jaState.processingState == ja.ProcessingState.completed;

      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
      );

      if (isCompleted) {
        _handleTrackCompleted();
      }
    });

    _audioService.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _audioService.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  void _handleTrackCompleted() {
    if (state.repeatMode == RepeatMode.one && state.currentTrack != null) {
      _audioService.seek(Duration.zero);
      _audioService.resume();
    } else {
      next();
    }
  }

  Future<void> playTrack(Track track, {List<Track>? newQueue}) async {
    final queue = newQueue ?? [track];
    final index = queue.indexWhere((t) => t.id == track.id);

    state = state.copyWith(
      currentTrack: track,
      queue: queue,
      queueIndex: index >= 0 ? index : 0,
      position: Duration.zero,
      duration: track.duration,
    );

    await _audioService.playTrack(track);
  }

  Future<void> togglePlayPause() async {
    if (state.currentTrack == null) {
      if (state.queue.isNotEmpty) {
        await playTrack(state.queue.first);
      }
      return;
    }

    if (state.isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.resume();
    }
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;

    int nextIndex;
    if (state.isShuffle) {
      nextIndex = Random().nextInt(state.queue.length);
    } else {
      nextIndex = state.queueIndex + 1;
      if (nextIndex >= state.queue.length) {
        if (state.repeatMode == RepeatMode.all) {
          nextIndex = 0;
        } else {
          return; // End of queue
        }
      }
    }

    final nextTrack = state.queue[nextIndex];
    state = state.copyWith(queueIndex: nextIndex);
    await playTrack(nextTrack, newQueue: state.queue);
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;

    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex = state.queueIndex - 1;
    if (prevIndex < 0) {
      prevIndex = state.repeatMode == RepeatMode.all ? state.queue.length - 1 : 0;
    }

    final prevTrack = state.queue[prevIndex];
    state = state.copyWith(queueIndex: prevIndex);
    await playTrack(prevTrack, newQueue: state.queue);
  }

  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
    await _audioService.seek(position);
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
    await _audioService.setVolume(state.volume);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
  }

  void addToQueue(Track track) {
    state = state.copyWith(queue: [...state.queue, track]);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final updated = List<Track>.from(state.queue)..removeAt(index);
    state = state.copyWith(queue: updated);
  }

  void clearQueue() {
    state = state.copyWith(queue: state.currentTrack != null ? [state.currentTrack!] : [], queueIndex: 0);
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerStateData>(PlayerNotifier.new);
