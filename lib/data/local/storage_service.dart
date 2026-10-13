import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';
import '../music_catalog.dart';

class LocalStorageService {
  static const String _storageFileName = 'spoticlone_data.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_storageFileName');
  }

  Future<Map<String, dynamic>> _readData() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return {
          'liked_track_ids': <String>[],
          'downloaded_tracks': <String, dynamic>{},
          'downloaded_tracks_metadata': <String, dynamic>{},
          'liked_tracks_metadata': <String, dynamic>{},
          'custom_playlists': <dynamic>[],
          'history_track_ids': <String>[],
        };
      }
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return {
        'liked_track_ids': <String>[],
        'downloaded_tracks': <String, dynamic>{},
        'downloaded_tracks_metadata': <String, dynamic>{},
        'liked_tracks_metadata': <String, dynamic>{},
        'custom_playlists': <dynamic>[],
        'history_track_ids': <String>[],
      };
    }
  }

  Future<void> _writeData(Map<String, dynamic> data) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<Set<String>> loadLikedTrackIds() async {
    final data = await _readData();
    final list = data['liked_track_ids'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toSet();
  }

  Future<void> saveLikedTrackIds(Set<String> ids) async {
    final data = await _readData();
    data['liked_track_ids'] = ids.toList();
    await _writeData(data);
  }

  Future<Map<String, String>> loadDownloadedTrackPaths() async {
    final data = await _readData();
    final map = data['downloaded_tracks'] as Map<String, dynamic>? ?? {};
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> saveDownloadedTrackPath(String trackId, String? localPath) async {
    final data = await _readData();
    final map = Map<String, dynamic>.from(data['downloaded_tracks'] as Map<String, dynamic>? ?? {});
    if (localPath == null) {
      map.remove(trackId);
    } else {
      map[trackId] = localPath;
    }
    data['downloaded_tracks'] = map;
    await _writeData(data);
  }

  Future<Map<String, Track>> loadDownloadedTracksMetadata() async {
    final data = await _readData();
    final map = data['downloaded_tracks_metadata'] as Map<String, dynamic>? ?? {};
    final result = <String, Track>{};
    for (final entry in map.entries) {
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = Track.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    return result;
  }

  Future<void> saveDownloadedTrackMetadata(Track track, {bool remove = false}) async {
    final data = await _readData();
    final map = Map<String, dynamic>.from(data['downloaded_tracks_metadata'] as Map<String, dynamic>? ?? {});
    if (remove) {
      map.remove(track.id);
    } else {
      map[track.id] = track.toJson();
    }
    data['downloaded_tracks_metadata'] = map;
    await _writeData(data);
  }

  Future<Map<String, Track>> loadLikedTracksMetadata() async {
    final data = await _readData();
    final map = data['liked_tracks_metadata'] as Map<String, dynamic>? ?? {};
    final result = <String, Track>{};
    for (final entry in map.entries) {
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = Track.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    return result;
  }

  Future<void> saveLikedTrackMetadata(Track track, {bool remove = false}) async {
    final data = await _readData();
    final map = Map<String, dynamic>.from(data['liked_tracks_metadata'] as Map<String, dynamic>? ?? {});
    if (remove) {
      map.remove(track.id);
    } else {
      map[track.id] = track.toJson();
    }
    data['liked_tracks_metadata'] = map;
    await _writeData(data);
  }

  Future<List<Playlist>> loadPlaylists() async {
    final data = await _readData();
    final customList = data['custom_playlists'] as List<dynamic>? ?? [];
    final customPlaylists = customList
        .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
        .toList();

    // Combine initial built-in playlists + custom playlists
    final allPlaylists = <Playlist>[
      ...MusicCatalog.initialPlaylists,
      ...customPlaylists,
    ];
    return allPlaylists;
  }

  Future<void> saveCustomPlaylists(List<Playlist> customPlaylists) async {
    final data = await _readData();
    data['custom_playlists'] = customPlaylists.map((p) => p.toJson()).toList();
    await _writeData(data);
  }

  Future<Map<String, String>> loadSpotifyCredentials() async {
    final data = await _readData();
    return {
      'client_id': (data['spotify_client_id'] ?? '').toString(),
      'client_secret': (data['spotify_client_secret'] ?? '').toString(),
    };
  }

  Future<void> saveSpotifyCredentials(String clientId, String clientSecret) async {
    final data = await _readData();
    data['spotify_client_id'] = clientId.trim();
    data['spotify_client_secret'] = clientSecret.trim();
    await _writeData(data);
  }

  Future<String> exportPlaylistsJson(List<Playlist> playlists) async {
    return const JsonEncoder.withIndent('  ').convert(
      playlists.map((p) => p.toJson()).toList(),
    );
  }

  Future<List<Playlist>> importPlaylistsJson(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);

    if (decoded is Map<String, dynamic>) {
      // 1. Wrapped list of playlists: { "playlists": [...] }
      if (decoded['playlists'] is List) {
        final list = decoded['playlists'] as List;
        return list.whereType<Map<String, dynamic>>().map((e) => Playlist.fromJson(e)).toList();
      }

      // 2. Object with items: { "items": [...] }
      if (decoded['items'] is List) {
        final items = decoded['items'] as List;
        return importPlaylistsJson(jsonEncode(items));
      }

      // 3. Single playlist object: { "title": "...", "tracks": [...] }
      if (decoded.containsKey('tracks') ||
          decoded.containsKey('trackList') ||
          decoded.containsKey('title') ||
          decoded.containsKey('name')) {
        return [Playlist.fromJson(decoded)];
      }
    }

    if (decoded is List) {
      if (decoded.isEmpty) return [];

      final first = decoded.first;
      // If items look like playlists (contain 'tracks' or 'trackList' or 'playlist_id')
      if (first is Map<String, dynamic> &&
          (first.containsKey('tracks') || first.containsKey('trackList') || first.containsKey('playlist_id'))) {
        return decoded.whereType<Map<String, dynamic>>().map((e) => Playlist.fromJson(e)).toList();
      }

      // Otherwise, items are a list of tracks: [ { "title": "...", "artist": "..." }, ... ]
      // Auto-wrap into an "Imported Playlist"
      final tracks = decoded
          .whereType<Map<String, dynamic>>()
          .map((e) {
            final trackData = e.containsKey('track') && e['track'] is Map<String, dynamic>
                ? e['track'] as Map<String, dynamic>
                : e;
            return Track.fromJson(trackData);
          })
          .toList();

      return [
        Playlist(
          id: 'pl-json-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Imported Playlist',
          description: 'Imported from JSON (${tracks.length} tracks)',
          coverUrl: tracks.isNotEmpty
              ? tracks.first.coverUrl
              : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
          tracks: tracks,
          isCustom: true,
          createdAt: DateTime.now(),
        ),
      ];
    }

    return [];
  }
}
