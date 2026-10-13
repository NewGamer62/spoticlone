import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class YoutubeAudioResolver {
  static final YoutubeExplode _yt = YoutubeExplode();

  static YoutubeExplode get ytClient => _yt;

  /// Selects the best AudioOnlyStreamInfo favoring MP4/AAC (itag 140) for Windows Media Foundation compatibility
  static AudioOnlyStreamInfo? selectPreferredAudioStream(StreamManifest manifest) {
    if (manifest.audioOnly.isEmpty) return null;

    // 1. Look for itag 140 (128kbps AAC in MP4 container - standard WMF audio format)
    for (final stream in manifest.audioOnly) {
      if (stream.tag == 140) {
        return stream;
      }
    }

    // 2. Look for any MP4/AAC streams and pick highest bitrate
    final mp4Streams = manifest.audioOnly.where((s) {
      final containerName = s.container.name.toLowerCase();
      final codec = s.audioCodec.toLowerCase();
      return containerName == 'mp4' ||
          containerName == 'm4a' ||
          codec.contains('mp4') ||
          codec.contains('aac');
    }).toList();

    if (mp4Streams.isNotEmpty) {
      mp4Streams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
      return mp4Streams.first;
    }

    // 3. Fallback to stream with highest bitrate
    return manifest.audioOnly.withHighestBitrate();
  }

  /// Resolves the preferred AudioOnlyStreamInfo for a track
  static Future<AudioOnlyStreamInfo?> resolvePreferredStreamInfo(Track track) async {
    try {
      final query = '${track.title} ${track.artist} audio';
      final searchResults = await _yt.search.search(query);
      if (searchResults.isEmpty) return null;

      final videoId = searchResults.first.id;
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      return selectPreferredAudioStream(manifest);
    } catch (e) {
      return null;
    }
  }

  /// Resolve a streamable audio URL from a YouTube search query or track metadata
  static Future<String?> resolveAudioStream(Track track) async {
    // If the track already has a direct valid stream, return it
    if (track.audioUrl != null &&
        (track.audioUrl!.startsWith('http://') ||
         track.audioUrl!.startsWith('https://')) &&
        !track.audioUrl!.contains('youtube.com/watch') &&
        !track.audioUrl!.contains('youtu.be')) {
      return track.audioUrl;
    }

    final streamInfo = await resolvePreferredStreamInfo(track);
    return streamInfo?.url.toString();
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

      await for (final video in _yt.playlists.getVideos(playlistId).take(2000)) {
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
