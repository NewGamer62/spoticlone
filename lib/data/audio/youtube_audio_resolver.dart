import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class YoutubeAudioResolver {
  static final YoutubeExplode _yt = YoutubeExplode();

  /// Resolve a streamable audio URL from a YouTube search query or track metadata
  static Future<String?> resolveAudioStream(Track track) async {
    // If the track already has a direct valid stream, return it
    if (track.audioUrl != null &&
        (track.audioUrl!.startsWith('http://') ||
         track.audioUrl!.startsWith('https://')) &&
        !track.audioUrl!.contains('youtube.com/watch')) {
      return track.audioUrl;
    }

    try {
      final query = '${track.title} ${track.artist} audio';
      final searchResults = await _yt.search.search(query);
      if (searchResults.isEmpty) return null;

      final videoId = searchResults.first.id;
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnlyStream = manifest.audioOnly.withHighestBitrate();
      return audioOnlyStream.url.toString();
    } catch (e) {
      // Stream resolution fallback
      return null;
    }
  }

  /// Search YouTube for tracks
  static Future<List<Track>> searchYoutubeTracks(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      final tracks = <Track>[];

      for (final video in searchResults.take(15)) {
        tracks.add(
          Track(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            album: 'YouTube Music',
            duration: video.duration ?? const Duration(minutes: 3),
            coverUrl: video.thumbnails.highResUrl,
            audioUrl: null, // Resolved on-demand when user clicks play
          ),
        );
      }
      return tracks;
    } catch (e) {
      return [];
    }
  }

  /// Extracts a YouTube playlist ID from a URL
  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (match != null) return match.group(1);

    if (RegExp(r'^(PL|OLAK|UU|FL|RD)[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  /// Fetches an entire playlist from YouTube / YouTube Music
  static Future<Playlist?> fetchYoutubePlaylist(String playlistId) async {
    try {
      final ytPlaylist = await _yt.playlists.get(playlistId);
      final tracks = <Track>[];

      await for (final video in _yt.playlists.getVideos(playlistId).take(200)) {
        tracks.add(
          Track(
            id: 'yt-${video.id.value}',
            title: video.title,
            artist: video.author,
            album: ytPlaylist.title,
            duration: video.duration ?? const Duration(minutes: 3),
            coverUrl: video.thumbnails.highResUrl,
            audioUrl: null, // Resolves on demand
          ),
        );
      }

      return Playlist(
        id: 'yt-pl-$playlistId',
        title: ytPlaylist.title,
        description: ytPlaylist.description,
        coverUrl: ytPlaylist.thumbnails.highResUrl,
        tracks: tracks,
        isCustom: true,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static void dispose() {
    _yt.close();
  }
}
