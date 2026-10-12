import 'dart:convert';
import 'dart:io';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class SpotifyImportService {
  static final HttpClient _client = HttpClient();

  /// Obtains a short-lived bearer token using Spotify Client Credentials Flow
  static Future<String?> getAccessToken({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      final uri = Uri.parse('https://accounts.spotify.com/api/token');
      final request = await _client.postUrl(uri);

      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      request.headers.set('Authorization', 'Basic $credentials');
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');

      final body = utf8.encode('grant_type=client_credentials');
      request.contentLength = body.length;
      request.add(body);

      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['access_token'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Extracts the Spotify playlist ID from a URL, URI or raw ID
  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Pattern 1: URI spotify:playlist:37i9dQZF1DXcBWIGoYBM5M
    final uriMatch = RegExp(r'spotify:playlist:([a-zA-Z0-9]+)').firstMatch(trimmed);
    if (uriMatch != null) return uriMatch.group(1);

    // Pattern 2: URL https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=...
    final urlMatch = RegExp(r'open\.spotify\.com\/playlist\/([a-zA-Z0-9]+)').firstMatch(trimmed);
    if (urlMatch != null) return urlMatch.group(1);

    // Pattern 3: Raw ID (typically 22 alphanumeric chars)
    if (RegExp(r'^[a-zA-Z0-9]{15,30}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  /// Fetches playlist metadata and all tracks from Spotify API
  static Future<Playlist?> fetchPlaylist({
    required String playlistId,
    required String accessToken,
  }) async {
    try {
      // 1. Fetch playlist metadata
      final metaUri = Uri.parse('https://api.spotify.com/v1/playlists/$playlistId');
      final metaReq = await _client.getUrl(metaUri);
      metaReq.headers.set('Authorization', 'Bearer $accessToken');
      final metaRes = await metaReq.close();

      if (metaRes.statusCode != 200) {
        return null;
      }

      final metaBody = await metaRes.transform(utf8.decoder).join();
      final meta = jsonDecode(metaBody) as Map<String, dynamic>;

      final title = meta['name'] as String? ?? 'Imported Spotify Playlist';
      final description = meta['description'] as String? ?? '';
      
      String coverUrl = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80';
      final images = meta['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final firstImg = images.first as Map<String, dynamic>;
        coverUrl = firstImg['url'] as String? ?? coverUrl;
      }

      // 2. Extract tracks (with pagination support up to 500 tracks)
      final tracks = <Track>[];
      var nextUrl = 'https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=100';

      while (nextUrl.isNotEmpty && tracks.length < 500) {
        final trReq = await _client.getUrl(Uri.parse(nextUrl));
        trReq.headers.set('Authorization', 'Bearer $accessToken');
        final trRes = await trReq.close();

        if (trRes.statusCode != 200) break;

        final trBody = await trRes.transform(utf8.decoder).join();
        final trData = jsonDecode(trBody) as Map<String, dynamic>;

        final items = trData['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final t = (item as Map<String, dynamic>)['track'] as Map<String, dynamic>?;
          if (t == null) continue;

          final trackId = t['id'] as String? ?? 'sp-${DateTime.now().microsecondsSinceEpoch}-${tracks.length}';
          final trackName = t['name'] as String? ?? 'Unknown Title';
          
          final artistsList = t['artists'] as List<dynamic>? ?? [];
          final artistNames = artistsList
              .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .join(', ');

          final albumObj = t['album'] as Map<String, dynamic>?;
          final albumName = albumObj?['name'] as String? ?? 'Spotify Album';
          
          String trackCover = coverUrl;
          final albumImages = albumObj?['images'] as List<dynamic>?;
          if (albumImages != null && albumImages.isNotEmpty) {
            final imgMap = albumImages.first as Map<String, dynamic>;
            trackCover = imgMap['url'] as String? ?? trackCover;
          }

          final durationMs = t['duration_ms'] as int? ?? 180000;

          tracks.add(
            Track(
              id: 'sp-$trackId',
              title: trackName,
              artist: artistNames.isEmpty ? 'Unknown Artist' : artistNames,
              album: albumName,
              duration: Duration(milliseconds: durationMs),
              coverUrl: trackCover,
              audioUrl: null, // Resolves dynamically when played or downloaded
            ),
          );
        }

        final next = trData['next'] as String?;
        nextUrl = next ?? '';
      }

      return Playlist(
        id: 'sp-pl-$playlistId',
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
}
