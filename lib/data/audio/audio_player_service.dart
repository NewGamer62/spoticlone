import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/track.dart';
import 'youtube_audio_resolver.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Track? _currentTrack;

  AudioPlayer get player => _player;
  Track? get currentTrack => _currentTrack;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<bool> playTrack(Track track) async {
    _currentTrack = track;
    try {
      // 1. Check if track is downloaded locally on disk (Offline Mode)
      if (track.localFilePath != null && track.localFilePath!.isNotEmpty) {
        final localFile = File(track.localFilePath!);
        if (await localFile.exists()) {
          await _player.setFilePath(localFile.path);
          await _player.play();
          return true;
        }
      }

      // 2. Otherwise stream from URL
      String? streamUrl = track.audioUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await YoutubeAudioResolver.resolveAudioStream(track);
      }

      streamUrl ??= 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3';

      await _player.setUrl(streamUrl);
      await _player.play();
      return true;
    } catch (e) {
      // Graceful playback error handling
      return false;
    }
  }

  Future<void> resume() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> seek(Duration position) async => _player.seek(position);
  Future<void> setVolume(double volume) async => _player.setVolume(volume);

  Future<void> dispose() async {
    await _player.dispose();
  }
}
