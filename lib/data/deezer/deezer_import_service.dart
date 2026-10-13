import 'dart:convert';
import 'dart:io';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class DeezerImportService {
  static final HttpClient _client = HttpClient();

  /// Extracts the Deezer playlist ID from a URL or raw ID
  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Pattern: deezer.com/fr/playlist/123456789 ou deezer.com/playlist/123456789
    final match = RegExp(r'playlist\/([0-9]+)').firstMatch(trimmed);
    if (match != null) return match.group(1);

    if (RegExp(r'^[0-9]{5,20}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  /// Fetches playlist metadata and all tracks from Deezer Public API (no credentials required)
  static Future<Playlist?> fetchPlaylist(String playlistId) async {
    try {
      final uri = Uri.parse('https://api.deezer.com/playlist/$playlistId');
      final req = await _client.getUrl(uri);
      req.headers.set('User-Agent', 'Mozilla/5.0');
      final res = await req.close();

      if (res.statusCode != 200) return null;

      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data.containsKey('error')) return null;

      final title = data['title'] as String? ?? 'Imported Deezer Playlist';
      final description = data['description'] as String? ?? '';
      final coverUrl = data['picture_xl'] as String? ??
          data['picture_medium'] as String? ??
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80';

      final tracks = <Track>[];
      final tracksData = data['tracks'] as Map<String, dynamic>?;
      final initialItems = tracksData?['data'] as List<dynamic>? ?? [];

      for (final item in initialItems) {
        if (item is Map<String, dynamic>) {
          tracks.add(_parseDeezerTrack(item, coverUrl, title));
        }
      }

      final totalTracks = data['nb_tracks'] as int? ?? (tracksData?['total'] as int? ?? tracks.length);
      var index = tracks.length;

      // Paginate Deezer tracks endpoint if more tracks exist
      while (tracks.length < totalTracks && index < 2000) {
        final pageUri = Uri.parse('https://api.deezer.com/playlist/$playlistId/tracks?limit=100&index=$index');
        final pageReq = await _client.getUrl(pageUri);
        pageReq.headers.set('User-Agent', 'Mozilla/5.0');
        final pageRes = await pageReq.close();
        if (pageRes.statusCode != 200) break;

        final pageBody = await pageRes.transform(utf8.decoder).join();
        final pageData = jsonDecode(pageBody) as Map<String, dynamic>;
        if (pageData.containsKey('error')) break;

        final pageItems = pageData['data'] as List<dynamic>? ?? [];
        if (pageItems.isEmpty) break;

        for (final item in pageItems) {
          if (item is Map<String, dynamic>) {
            tracks.add(_parseDeezerTrack(item, coverUrl, title));
          }
        }

        index += pageItems.length;
        if (pageItems.length < 100 || !pageData.containsKey('next')) {
          break;
        }
      }

      return Playlist(
        id: 'dz-pl-$playlistId',
        title: title,
        description: description,
        coverUrl: coverUrl,
        tracks: tracks,
        isCustom: true,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static Track _parseDeezerTrack(Map<String, dynamic> t, String fallbackCover, String fallbackAlbum) {
    final trackId = t['id'].toString();
    final trackTitle = t['title'] as String? ?? 'Unknown Title';

    final artistObj = t['artist'] as Map<String, dynamic>?;
    final artistName = artistObj?['name'] as String? ?? 'Unknown Artist';

    final albumObj = t['album'] as Map<String, dynamic>?;
    final albumTitle = albumObj?['title'] as String? ?? fallbackAlbum;
    final albumCover = albumObj?['cover_xl'] as String? ??
        albumObj?['cover_medium'] as String? ??
        fallbackCover;

    final durationSec = t['duration'] as int? ?? 180;
    final previewUrl = t['preview'] as String?;

    return Track(
      id: 'dz-$trackId',
      title: trackTitle,
      artist: artistName,
      album: albumTitle,
      duration: Duration(seconds: durationSec),
      coverUrl: albumCover,
      audioUrl: (previewUrl != null && previewUrl.isNotEmpty) ? previewUrl : null,
    );
  }
}
