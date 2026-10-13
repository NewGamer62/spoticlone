import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/track.dart';
import 'audio_preload_service.dart';
import 'download_service.dart';
import 'youtube_audio_resolver.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Track? _currentTrack;
  bool _audioSessionConfigured = false;

  AudioPlayerService() {
    _initAudioSession();
  }

  AudioPlayer get player => _player;
  Track? get currentTrack => _currentTrack;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> _initAudioSession() async {
    if (_audioSessionConfigured) return;
    _audioSessionConfigured = true;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      }
    } catch (e) {
      debugPrint('AudioSession configuration error: $e');
    }
  }

  Future<bool> playTrack(Track track) async {
    _currentTrack = track;
    await _initAudioSession();
    try {
      // 1. Check if track is downloaded locally on disk (Offline Mode)
      File? localFile;
      if (track.localFilePath != null && track.localFilePath!.isNotEmpty) {
        final f = File(track.localFilePath!);
        if (await f.exists() && await f.length() > 0) {
          localFile = f;
        }
      }

      // Autonomous disk check if localFilePath was not set or missing
      if (localFile == null) {
        try {
          final dir = await DownloadService.getDownloadsDirectory();
          final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
          for (final ext in ['.m4a', '.mp3', '.webm']) {
            final candidate = File('${dir.path}/$safeId$ext');
            if (await candidate.exists() && await candidate.length() > 0) {
              localFile = candidate;
              break;
            }
          }
        } catch (e) {
          debugPrint('Autonomous disk check notice: $e');
        }
      }

      if (localFile != null) {
        try {
          debugPrint('Playing local offline track from: ${localFile.path}');
          await _player.setFilePath(localFile.path);
          await _player.play();
          return true;
        } catch (localFileError) {
          debugPrint('Local file playback failed (${localFile.path}): $localFileError. Falling back to remote streaming.');
        }
      }

      // 2. Otherwise stream from URL (Check Preload Cache first)
      String? streamUrl = AudioPreloadService.getCachedStreamUrl(track.id);
      if (streamUrl == null || streamUrl.isEmpty) {
        final directUrl = track.audioUrl;
        if (directUrl != null &&
            (directUrl.startsWith('http://') || directUrl.startsWith('https://')) &&
            !directUrl.contains('youtube.com') &&
            !directUrl.contains('youtu.be')) {
          streamUrl = directUrl;
        } else {
          streamUrl = await YoutubeAudioResolver.resolveAudioStream(track);
        }
        if (streamUrl != null) {
          AudioPreloadService.cacheStreamUrl(track.id, streamUrl);
        }
      }

      streamUrl ??= 'https://raw.githubusercontent.com/rafaelreis-hotmart/Audio-Sample-files/master/sample.mp3';

      try {
        debugPrint('Streaming audio for "${track.title}" from URL: $streamUrl');
        await _player.setUrl(streamUrl);
        await _player.play();
        return true;
      } catch (playError) {
        debugPrint('Primary stream URL failed for "${track.title}": $playError. Attempting fresh stream resolution...');
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
    } catch (e, stack) {
      debugPrint('Error playing track "${track.title}" (${track.id}): $e\n$stack');
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
