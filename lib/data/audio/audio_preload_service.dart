import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/track.dart';
import 'youtube_audio_resolver.dart';

class AudioPreloadService {
  // In-memory cache for resolved audio stream URLs (key: trackId, value: streamUrl)
  static final Map<String, String> _streamCache = {};
  static final Set<String> _resolvingTrackIds = {};

  /// Retrieves an already cached stream URL if available
  static String? getCachedStreamUrl(String trackId) => _streamCache[trackId];

  /// Stores a resolved stream URL into the fast cache
  static void cacheStreamUrl(String trackId, String streamUrl) {
    _streamCache[trackId] = streamUrl;
  }

  /// Preloads the audio stream for the next track in queue asynchronously
  static void preloadTrack(Track? track) {
    if (track == null) return;
    final trackId = track.id;

    // Already cached or downloaded locally
    if (_streamCache.containsKey(trackId)) return;
    if (track.localFilePath != null && track.localFilePath!.isNotEmpty) return;
    if (track.audioUrl != null &&
        (track.audioUrl!.startsWith('http://') || track.audioUrl!.startsWith('https://')) &&
        !track.audioUrl!.contains('youtube.com/watch')) {
      _streamCache[trackId] = track.audioUrl!;
      return;
    }

    if (_resolvingTrackIds.contains(trackId)) return;
    _resolvingTrackIds.add(trackId);

    // Resolve in background without blocking main execution
    unawaited(
      YoutubeAudioResolver.resolveAudioStream(track).then((resolvedUrl) {
        _resolvingTrackIds.remove(trackId);
        if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
          _streamCache[trackId] = resolvedUrl;
        }
      }).catchError((_) {
        _resolvingTrackIds.remove(trackId);
      }),
    );
  }

  /// Clears cache if needed
  static void clear() {
    _streamCache.clear();
    _resolvingTrackIds.clear();
  }
}

final audioPreloadServiceProvider = Provider<AudioPreloadService>((ref) => AudioPreloadService());
