import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/track.dart';
import 'audio_preload_service.dart';
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

      // 2. Otherwise stream from URL (Check Preload Cache first)
      String? streamUrl = AudioPreloadService.getCachedStreamUrl(track.id) ?? track.audioUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await YoutubeAudioResolver.resolveAudioStream(track);
        if (streamUrl != null) {
          AudioPreloadService.cacheStreamUrl(track.id, streamUrl);
        }
      }

      streamUrl ??= 'https://raw.githubusercontent.com/rafaelreis-hotmart/Audio-Sample-files/master/sample.mp3';

      try {
        await _player.setUrl(streamUrl);
        await _player.play();
        return true;
      } catch (playError) {
        // If stream URL failed (e.g. expired GoogleVideo token), re-resolve once fresh
        final freshUrl = await YoutubeAudioResolver.resolveAudioStream(track);
        if (freshUrl != null && freshUrl != streamUrl) {
          AudioPreloadService.cacheStreamUrl(track.id, freshUrl);
          await _player.setUrl(freshUrl);
          await _player.play();
          return true;
        }
        rethrow;
      }
    } catch (_) {
      // Graceful playback error handling & fallback
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
