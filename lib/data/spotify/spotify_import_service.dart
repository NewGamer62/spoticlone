import 'dart:convert';
import 'dart:io';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class SpotifyImportService {
  static final HttpClient _client = HttpClient();

  /// Extracts the Spotify playlist ID from a URL, URI or raw ID
  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final uriMatch = RegExp(r'spotify:playlist:([a-zA-Z0-9]+)').firstMatch(trimmed);
    if (uriMatch != null) return uriMatch.group(1);

    final urlMatch = RegExp(r'open\.spotify\.com\/playlist\/([a-zA-Z0-9]+)').firstMatch(trimmed);
    if (urlMatch != null) return urlMatch.group(1);

    if (RegExp(r'^[a-zA-Z0-9]{15,30}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  /// 1-CLICK SCRAPER: Extracts public playlist metadata and tracks from Spotify embed
  /// No API keys, no developer account required!
  static Future<Playlist?> fetchPublicPlaylist(String playlistId) async {
    try {
      final embedUrl = Uri.parse('https://open.spotify.com/embed/playlist/$playlistId');
      final request = await _client.getUrl(embedUrl);
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      final response = await request.close();

      if (response.statusCode != 200) {
        return null;
      }

      final html = await response.transform(utf8.decoder).join();
      final scriptMatch = RegExp(r'<script id="__NEXT_DATA__" type="application/json">([\s\S]*?)</script>').firstMatch(html);
      if (scriptMatch == null) return null;

      final jsonContent = scriptMatch.group(1);
      if (jsonContent == null) return null;

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final props = data['props'] as Map<String, dynamic>?;
      final pageProps = props?['pageProps'] as Map<String, dynamic>?;
      final state = pageProps?['state'] as Map<String, dynamic>?;
      final dataEntity = state?['data'] as Map<String, dynamic>?;
      final entity = dataEntity?['entity'] as Map<String, dynamic>?;

      if (entity == null) return null;

      final title = entity['title'] as String? ?? 'Imported Playlist';
      final subtitle = entity['subtitle'] as String? ?? '';
      
      // Extract Cover
      String coverUrl = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80';
      final visual = entity['visualIdentity'] as Map<String, dynamic>?;
      final images = visual?['image'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final lastImg = images.last as Map<String, dynamic>;
        coverUrl = lastImg['url'] as String? ?? coverUrl;
      }

      // Extract Track list
      final trackList = entity['trackList'] as List<dynamic>? ?? [];
      final tracks = <Track>[];

      for (var i = 0; i < trackList.length; i++) {
        final item = trackList[i] as Map<String, dynamic>;
        final trackTitle = item['title'] as String? ?? 'Unknown Title';
        final trackArtist = item['subtitle'] as String? ?? 'Unknown Artist';
        final durationMs = item['duration'] as int? ?? 180000;
        final uri = item['uri'] as String? ?? 'sp-$i';
        final trackId = uri.replaceFirst('spotify:track:', '');

        tracks.add(
          Track(
            id: 'sp-$trackId',
            title: trackTitle,
            artist: trackArtist,
            album: title,
            duration: Duration(milliseconds: durationMs),
            coverUrl: coverUrl,
            audioUrl: null, // Resolved on-demand via YouTube
          ),
        );
      }

      return Playlist(
        id: 'sp-pl-$playlistId',
        title: title,
        description: subtitle,
        coverUrl: coverUrl,
        tracks: tracks,
        isCustom: true,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

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

  /// Fetches playlist metadata and all tracks from Spotify Official API
  static Future<Playlist?> fetchPlaylist({
    required String playlistId,
    required String accessToken,
  }) async {
    try {
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

      final tracks = <Track>[];
      var nextUrl = 'https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=100';

      while (nextUrl.isNotEmpty && tracks.length < 2000) {
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
              audioUrl: null,
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
