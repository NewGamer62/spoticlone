import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/audio/download_service.dart';
import '../../data/audio/youtube_audio_resolver.dart';
import '../../data/deezer/deezer_import_service.dart';
import '../../data/local/storage_service.dart';
import '../../data/music_catalog.dart';
import '../../data/spotify/spotify_import_service.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class LibraryState {
  final Set<String> likedTrackIds;
  final Map<String, String> downloadedPaths; // trackId -> localFilePath
  final Map<String, Track> downloadedMetadata; // trackId -> Track
  final Map<String, Track> likedMetadata; // trackId -> Track
  final Set<String> downloadingTrackIds;
  final List<Playlist> playlists;
  final bool isLoading;

  const LibraryState({
    this.likedTrackIds = const {},
    this.downloadedPaths = const {},
    this.downloadedMetadata = const {},
    this.likedMetadata = const {},
    this.downloadingTrackIds = const {},
    this.playlists = const [],
    this.isLoading = true,
  });

  LibraryState copyWith({
    Set<String>? likedTrackIds,
    Map<String, String>? downloadedPaths,
    Map<String, Track>? downloadedMetadata,
    Map<String, Track>? likedMetadata,
    Set<String>? downloadingTrackIds,
    List<Playlist>? playlists,
    bool? isLoading,
  }) {
    return LibraryState(
      likedTrackIds: likedTrackIds ?? this.likedTrackIds,
      downloadedPaths: downloadedPaths ?? this.downloadedPaths,
      downloadedMetadata: downloadedMetadata ?? this.downloadedMetadata,
      likedMetadata: likedMetadata ?? this.likedMetadata,
      downloadingTrackIds: downloadingTrackIds ?? this.downloadingTrackIds,
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, Track> get _allKnownTracks {
    final map = <String, Track>{};
    // 1. Built-in catalog tracks
    for (final t in MusicCatalog.allTracks) {
      map[t.id] = t;
    }
    // 2. All tracks from all playlists (custom, imported, built-in)
    for (final pl in playlists) {
      for (final t in pl.tracks) {
        map[t.id] = t;
      }
    }
    // 3. Stored downloaded tracks metadata
    for (final entry in downloadedMetadata.entries) {
      map[entry.key] = entry.value;
    }
    // 4. Stored liked tracks metadata
    for (final entry in likedMetadata.entries) {
      map[entry.key] = entry.value;
    }
    return map;
  }

  List<Track> get likedTracks {
    final pool = _allKnownTracks;
    return likedTrackIds
        .map((id) => pool[id])
        .whereType<Track>()
        .map((t) => _attachDownloadInfo(t))
        .toList();
  }

  List<Track> get downloadedTracks {
    final pool = _allKnownTracks;
    return downloadedPaths.entries.map((entry) {
      final t = pool[entry.key] ??
          Track(
            id: entry.key,
            title: entry.key,
            artist: 'Offline Track',
            album: 'Downloads',
            duration: const Duration(seconds: 180),
            coverUrl: Track.defaultCoverUrl,
            localFilePath: entry.value,
            isDownloaded: true,
          );
      return _attachDownloadInfo(t);
    }).toList();
  }

  Track _attachDownloadInfo(Track track) {
    final localPath = downloadedPaths[track.id];
    return track.copyWith(
      localFilePath: localPath,
      isDownloaded: localPath != null,
      isLiked: likedTrackIds.contains(track.id),
    );
  }

  Track decorateTrack(Track track) => _attachDownloadInfo(track);
}

final storageServiceSingleton = LocalStorageService();

class LibraryNotifier extends Notifier<LibraryState> {
  late final LocalStorageService _storage;

  @override
  LibraryState build() {
    _storage = storageServiceSingleton;
    _loadInitialData();
    return const LibraryState();
  }

  Future<void> _loadInitialData() async {
    final likedIds = await _storage.loadLikedTrackIds();
    final downloaded = await _storage.loadDownloadedTrackPaths();
    final downloadedMeta = await _storage.loadDownloadedTracksMetadata();
    final likedMeta = await _storage.loadLikedTracksMetadata();
    final playlists = await _storage.loadPlaylists();
    state = state.copyWith(
      likedTrackIds: likedIds,
      downloadedPaths: downloaded,
      downloadedMetadata: downloadedMeta,
      likedMetadata: likedMeta,
      playlists: playlists,
      isLoading: false,
    );
  }

  Future<void> toggleLike(Track track) async {
    final newSet = Set<String>.from(state.likedTrackIds);
    final newLikedMeta = Map<String, Track>.from(state.likedMetadata);
    if (newSet.contains(track.id)) {
      newSet.remove(track.id);
      newLikedMeta.remove(track.id);
      await _storage.saveLikedTrackMetadata(track, remove: true);
    } else {
      newSet.add(track.id);
      newLikedMeta[track.id] = track;
      await _storage.saveLikedTrackMetadata(track);
    }
    state = state.copyWith(likedTrackIds: newSet, likedMetadata: newLikedMeta);
    await _storage.saveLikedTrackIds(newSet);
  }

  bool isLiked(String trackId) => state.likedTrackIds.contains(trackId);
  bool isDownloaded(String trackId) => state.downloadedPaths.containsKey(trackId);
  bool isDownloading(String trackId) => state.downloadingTrackIds.contains(trackId);

  Future<void> toggleDownload(Track track) async {
    final trackId = track.id;
    if (isDownloaded(trackId)) {
      // Remove download
      final path = state.downloadedPaths[trackId];
      if (path != null) {
        await DownloadService.deleteDownloadedTrack(path);
      }
      final updatedMap = Map<String, String>.from(state.downloadedPaths)..remove(trackId);
      final updatedMeta = Map<String, Track>.from(state.downloadedMetadata)..remove(trackId);
      state = state.copyWith(
        downloadedPaths: updatedMap,
        downloadedMetadata: updatedMeta,
      );
      await _storage.saveDownloadedTrackPath(trackId, null);
      await _storage.saveDownloadedTrackMetadata(track, remove: true);
    } else {
      // Start download
      state = state.copyWith(downloadingTrackIds: {...state.downloadingTrackIds, trackId});
      final downloadedPath = await DownloadService.downloadTrack(track);

      final updatedDownloading = Set<String>.from(state.downloadingTrackIds)..remove(trackId);
      if (downloadedPath != null) {
        final updatedMap = Map<String, String>.from(state.downloadedPaths)..[trackId] = downloadedPath;
        final updatedTrack = track.copyWith(
          localFilePath: downloadedPath,
          isDownloaded: true,
        );
        final updatedMeta = Map<String, Track>.from(state.downloadedMetadata)..[trackId] = updatedTrack;
        state = state.copyWith(
          downloadedPaths: updatedMap,
          downloadedMetadata: updatedMeta,
          downloadingTrackIds: updatedDownloading,
        );
        await _storage.saveDownloadedTrackPath(trackId, downloadedPath);
        await _storage.saveDownloadedTrackMetadata(updatedTrack);
      } else {
        state = state.copyWith(downloadingTrackIds: updatedDownloading);
      }
    }
  }

  Future<void> createPlaylist(String title, String description) async {
    final newPlaylist = Playlist(
      id: 'pl-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      tracks: [],
      isCustom: true,
      createdAt: DateTime.now(),
    );

    final updatedPlaylists = [...state.playlists, newPlaylist];
    state = state.copyWith(playlists: updatedPlaylists);
    final customOnly = updatedPlaylists.where((p) => p.isCustom).toList();
    await _storage.saveCustomPlaylists(customOnly);
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final updatedPlaylists = state.playlists.map((pl) {
      if (pl.id == playlistId) {
        if (pl.tracks.any((t) => t.id == track.id)) return pl;
        return pl.copyWith(tracks: [...pl.tracks, track]);
      }
      return pl;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
    final customOnly = updatedPlaylists.where((p) => p.isCustom).toList();
    await _storage.saveCustomPlaylists(customOnly);
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final updatedPlaylists = state.playlists.map((pl) {
      if (pl.id == playlistId) {
        final updatedTracks = pl.tracks.where((t) => t.id != trackId).toList();
        return pl.copyWith(tracks: updatedTracks);
      }
      return pl;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
    final customOnly = updatedPlaylists.where((p) => p.isCustom).toList();
    await _storage.saveCustomPlaylists(customOnly);
  }

  Future<String> exportPlaylistsAsJson() async {
    return _storage.exportPlaylistsJson(state.playlists);
  }

  Future<void> importPlaylistsFromJson(String jsonString) async {
    final imported = await _storage.importPlaylistsJson(jsonString);
    final updatedPlaylists = List<Playlist>.from(state.playlists);

    for (final newPl in imported) {
      final index = updatedPlaylists.indexWhere((p) => p.id == newPl.id);
      if (index >= 0) {
        updatedPlaylists[index] = newPl; // Update existing
      } else {
        updatedPlaylists.add(newPl); // Append if new
      }
    }

    state = state.copyWith(playlists: updatedPlaylists);
    final customOnly = updatedPlaylists.where((p) => p.isCustom).toList();
    await _storage.saveCustomPlaylists(customOnly);
  }

  Future<Map<String, String>> getSpotifyCredentials() async {
    return _storage.loadSpotifyCredentials();
  }

  Future<void> saveSpotifyCredentials(String clientId, String clientSecret) async {
    await _storage.saveSpotifyCredentials(clientId, clientSecret);
  }

  Future<Playlist> importPlaylistFromAnyPlatform(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw Exception('Veuillez entrer un lien valide.');
    }

    // 1. YouTube / YouTube Music detection
    if (trimmed.contains('youtube.com') || trimmed.contains('youtu.be') || trimmed.startsWith('PL')) {
      final ytid = YoutubeAudioResolver.extractPlaylistId(trimmed);
      if (ytid == null) {
        throw Exception('Lien de playlist YouTube invalide.');
      }
      final pl = await YoutubeAudioResolver.fetchYoutubePlaylist(ytid);
      if (pl == null) {
        throw Exception('Impossible de charger la playlist YouTube. Vérifiez qu\'elle est publique ou non répertoriée.');
      }
      return _saveImportedPlaylist(pl);
    }

    // 2. Deezer detection
    if (trimmed.contains('deezer.com') || trimmed.contains('deezer.page.link')) {
      final dzid = DeezerImportService.extractPlaylistId(trimmed);
      if (dzid == null) {
        throw Exception('Lien de playlist Deezer invalide.');
      }
      final pl = await DeezerImportService.fetchPlaylist(dzid);
      if (pl == null) {
        throw Exception('Impossible de charger la playlist Deezer. Vérifiez qu\'elle est publique.');
      }
      return _saveImportedPlaylist(pl);
    }

    // 3. Spotify detection
    return importSpotifyPlaylistByUrl(trimmed);
  }

  Future<Playlist> _saveImportedPlaylist(Playlist playlist) async {
    final existingIndex = state.playlists.indexWhere((p) => p.id == playlist.id);
    List<Playlist> updated;
    if (existingIndex >= 0) {
      updated = List<Playlist>.from(state.playlists)..[existingIndex] = playlist;
    } else {
      updated = [...state.playlists, playlist];
    }

    state = state.copyWith(playlists: updated);
    final customOnly = updated.where((p) => p.isCustom).toList();
    await _storage.saveCustomPlaylists(customOnly);
    return playlist;
  }

  Future<Playlist> importSpotifyPlaylistByUrl(String playlistInput) async {
    final playlistId = SpotifyImportService.extractPlaylistId(playlistInput);
    if (playlistId == null) {
      throw Exception('Format de lien ou identifiant Spotify invalide.');
    }

    final playlist = await SpotifyImportService.fetchPublicPlaylist(playlistId);
    if (playlist == null) {
      throw Exception('Impossible de récupérer la playlist. Vérifiez que la playlist est bien publique.');
    }

    return _saveImportedPlaylist(playlist);
  }

  Future<Playlist> importSpotifyPlaylist({
    required String playlistInput,
    required String clientId,
    required String clientSecret,
  }) async {
    final playlistId = SpotifyImportService.extractPlaylistId(playlistInput);
    if (playlistId == null) {
      throw Exception('Format de lien ou identifiant Spotify invalide.');
    }

    final token = await SpotifyImportService.getAccessToken(
      clientId: clientId,
      clientSecret: clientSecret,
    );
    if (token == null) {
      throw Exception('Authentification Spotify échouée. Vérifiez vos identifiants Client ID et Secret.');
    }

    final playlist = await SpotifyImportService.fetchPlaylist(
      playlistId: playlistId,
      accessToken: token,
    );
    if (playlist == null) {
      throw Exception('Impossible de récupérer la playlist Spotify. Vérifiez que la playlist est bien publique.');
    }

    // Save credentials for next time
    await saveSpotifyCredentials(clientId, clientSecret);

    // Add to library
    final existingIndex = state.playlists.indexWhere((p) => p.id == playlist.id);
    List<Playlist> updated;
    if (existingIndex >= 0) {
      updated = List<Playlist>.from(state.playlists)..[existingIndex] = playlist;
    } else {
      updated = [...state.playlists, playlist];
    }

    state = state.copyWith(playlists: updated);
    final customOnly = updated.where((p) => p.isCustom).toList();
    await _storage.saveCustomPlaylists(customOnly);

    return playlist;
  }
}

final libraryProvider = NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);
