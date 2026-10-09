import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/audio/download_service.dart';
import '../../data/local/storage_service.dart';
import '../../data/music_catalog.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class LibraryState {
  final Set<String> likedTrackIds;
  final Map<String, String> downloadedPaths; // trackId -> localFilePath
  final Set<String> downloadingTrackIds;
  final List<Playlist> playlists;
  final bool isLoading;

  const LibraryState({
    this.likedTrackIds = const {},
    this.downloadedPaths = const {},
    this.downloadingTrackIds = const {},
    this.playlists = const [],
    this.isLoading = true,
  });

  LibraryState copyWith({
    Set<String>? likedTrackIds,
    Map<String, String>? downloadedPaths,
    Set<String>? downloadingTrackIds,
    List<Playlist>? playlists,
    bool? isLoading,
  }) {
    return LibraryState(
      likedTrackIds: likedTrackIds ?? this.likedTrackIds,
      downloadedPaths: downloadedPaths ?? this.downloadedPaths,
      downloadingTrackIds: downloadingTrackIds ?? this.downloadingTrackIds,
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Track> get likedTracks {
    return MusicCatalog.allTracks
        .where((t) => likedTrackIds.contains(t.id))
        .map((t) => _attachDownloadInfo(t))
        .toList();
  }

  List<Track> get downloadedTracks {
    return MusicCatalog.allTracks
        .where((t) => downloadedPaths.containsKey(t.id))
        .map((t) => _attachDownloadInfo(t))
        .toList();
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
    final playlists = await _storage.loadPlaylists();
    state = state.copyWith(
      likedTrackIds: likedIds,
      downloadedPaths: downloaded,
      playlists: playlists,
      isLoading: false,
    );
  }

  Future<void> toggleLike(Track track) async {
    final newSet = Set<String>.from(state.likedTrackIds);
    if (newSet.contains(track.id)) {
      newSet.remove(track.id);
    } else {
      newSet.add(track.id);
    }
    state = state.copyWith(likedTrackIds: newSet);
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
      state = state.copyWith(downloadedPaths: updatedMap);
      await _storage.saveDownloadedTrackPath(trackId, null);
    } else {
      // Start download
      state = state.copyWith(downloadingTrackIds: {...state.downloadingTrackIds, trackId});
      final downloadedPath = await DownloadService.downloadTrack(track);

      final updatedDownloading = Set<String>.from(state.downloadingTrackIds)..remove(trackId);
      if (downloadedPath != null) {
        final updatedMap = Map<String, String>.from(state.downloadedPaths)..[trackId] = downloadedPath;
        state = state.copyWith(
          downloadedPaths: updatedMap,
          downloadingTrackIds: updatedDownloading,
        );
        await _storage.saveDownloadedTrackPath(trackId, downloadedPath);
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
    final existingIds = state.playlists.map((p) => p.id).toSet();
    final toAdd = imported.where((p) => !existingIds.contains(p.id)).toList();

    final updated = [...state.playlists, ...toAdd];
    state = state.copyWith(playlists: updated);
    final customOnly = updated.where((p) => p.isCustom).toList();
    await _storage.saveCustomPlaylists(customOnly);
  }
}

final libraryProvider = NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);
