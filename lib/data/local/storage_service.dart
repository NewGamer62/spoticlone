import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/playlist.dart';
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
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
  }
}
