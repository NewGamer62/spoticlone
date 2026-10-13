import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoticlone/data/local/storage_service.dart';
import 'package:spoticlone/domain/models/playlist.dart';
import 'package:spoticlone/domain/models/track.dart';
import 'package:spoticlone/presentation/providers/library_provider.dart';

void main() {
  group('1. Flexible JSON import & resilient parsing', () {
    test('Track.fromJson parses various aliases and formats', () {
      // Name alias & artists list of objects
      final t1 = Track.fromJson({
        'name': 'Song Name',
        'artists': [
          {'name': 'Artist A'},
          {'name': 'Artist B'},
        ],
        'album': {'name': 'Album A'},
        'duration_ms': 210000,
        'uri': 'spotify:track:abc123xyz',
        'images': [
          {'url': 'https://example.com/cover.jpg'}
        ],
      });

      expect(t1.title, equals('Song Name'));
      expect(t1.artist, equals('Artist A, Artist B'));
      expect(t1.album, equals('Album A'));
      expect(t1.duration.inSeconds, equals(210));
      expect(t1.id, equals('abc123xyz'));
      expect(t1.coverUrl, equals('https://example.com/cover.jpg'));

      // MM:SS duration format and string artists list
      final t2 = Track.fromJson({
        'title': 'Track 2',
        'artists': ['Artist 1', 'Artist 2'],
        'duration': '04:15',
        'cover_url': 'https://example.com/c2.jpg',
      });

      expect(t2.duration.inSeconds, equals(255));
      expect(t2.artist, equals('Artist 1, Artist 2'));

      // Plain track from sorted JSON file
      final t3 = Track.fromJson({
        'title': 'Intro',
        'artist': 'Josman',
        'uri': 'spotify:track:6qvyN6NTUpdfOJRYjtSSd7',
        'cover_url': 'https://image-cdn.spotify.com/cover.jpg',
      });

      expect(t3.title, equals('Intro'));
      expect(t3.artist, equals('Josman'));
      expect(t3.id, equals('6qvyN6NTUpdfOJRYjtSSd7'));
      expect(t3.duration.inSeconds, equals(180)); // default fallback
    });

    test('Playlist.fromJson parses nested track wrappers', () {
      final json = {
        'name': 'My Spotify Mix',
        'id': 'pl-test-1',
        'items': [
          {
            'track': {
              'name': 'Nested Track',
              'artist': 'Nested Artist',
              'duration_seconds': 200,
            }
          }
        ],
      };

      final pl = Playlist.fromJson(json);
      expect(pl.title, equals('My Spotify Mix'));
      expect(pl.id, equals('pl-test-1'));
      expect(pl.tracks.length, equals(1));
      expect(pl.tracks.first.title, equals('Nested Track'));
      expect(pl.tracks.first.artist, equals('Nested Artist'));
    });

    test('LocalStorageService imports raw list of tracks and auto-wraps into playlist', () async {
      final storage = LocalStorageService();
      const rawTracksJson = '''[
        {"title": "Track One", "artist": "Singer A", "duration_seconds": 190},
        {"title": "Track Two", "artist": "Singer B", "duration_seconds": 210}
      ]''';

      final playlists = await storage.importPlaylistsJson(rawTracksJson);
      expect(playlists.length, equals(1));
      expect(playlists.first.title, equals('Imported Playlist'));
      expect(playlists.first.tracks.length, equals(2));
      expect(playlists.first.tracks[0].title, equals('Track One'));
      expect(playlists.first.tracks[1].title, equals('Track Two'));
    });

    test('LocalStorageService imports map with playlists key', () async {
      final storage = LocalStorageService();
      const wrappedJson = '''{
        "playlists": [
          {
            "id": "pl-wrapped-1",
            "title": "Wrapped Playlist",
            "tracks": [
              {"title": "Song", "artist": "Artist", "duration_seconds": 150}
            ]
          }
        ]
      }''';

      final playlists = await storage.importPlaylistsJson(wrappedJson);
      expect(playlists.length, equals(1));
      expect(playlists.first.id, equals('pl-wrapped-1'));
      expect(playlists.first.title, equals('Wrapped Playlist'));
      expect(playlists.first.tracks.length, equals(1));
    });

    test('LocalStorageService parses sorted_3LZ6AHR7Tj5DkLweLBJ61m.json without errors', () async {
      final file = File('sorted_3LZ6AHR7Tj5DkLweLBJ61m.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final storage = LocalStorageService();
        final playlists = await storage.importPlaylistsJson(content);

        expect(playlists.length, equals(1));
        final pl = playlists.first;
        expect(pl.tracks.length, greaterThan(10));
        expect(pl.tracks.first.title, equals('Intro'));
        expect(pl.tracks.first.artist, equals('Josman'));
        expect(pl.tracks.first.id, equals('6qvyN6NTUpdfOJRYjtSSd7'));
      }
    });

    test('LocalStorageService imports single track JSON and auto-wraps into playlist', () async {
      final storage = LocalStorageService();
      const singleTrackJson = '''{
        "title": "Bohemian Rhapsody",
        "artist": "Queen",
        "album": "A Night at the Opera",
        "duration_seconds": 354
      }''';

      final playlists = await storage.importPlaylistsJson(singleTrackJson);
      expect(playlists.length, equals(1));
      expect(playlists.first.title, equals('Imported Track'));
      expect(playlists.first.tracks.length, equals(1));
      expect(playlists.first.tracks.first.title, equals('Bohemian Rhapsody'));
      expect(playlists.first.tracks.first.artist, equals('Queen'));
      expect(playlists.first.tracks.first.duration.inSeconds, equals(354));
    });

    test('Track.fromJson extracts cover image from nested album.images', () {
      final track = Track.fromJson({
        'title': 'Comfortably Numb',
        'artist': 'Pink Floyd',
        'album': {
          'name': 'The Wall',
          'images': [
            {'url': 'https://example.com/the-wall.jpg'}
          ]
        }
      });

      expect(track.coverUrl, equals('https://example.com/the-wall.jpg'));
    });

    test('Playlist deterministic IDs enable upsert without duplicates', () {
      final pl1 = Playlist.fromJson({
        'name': 'Rock Classics',
        'tracks': [
          {'title': 'Song 1', 'artist': 'Artist 1'}
        ]
      });

      final pl2 = Playlist.fromJson({
        'name': 'Rock Classics',
        'tracks': [
          {'title': 'Song 1', 'artist': 'Artist 1'},
          {'title': 'Song 2', 'artist': 'Artist 2'}
        ]
      });

      expect(pl1.id, equals(pl2.id));
      expect(pl1.id, equals('pl-rock_classics'));
    });
  });

  group('2. LibraryState & aggregation across custom playlists', () {
    test('likedTracks and downloadedTracks aggregate across custom playlists and metadata', () {
      const customTrack1 = Track(
        id: 'custom-trk-1',
        title: 'Custom Track 1',
        artist: 'Indie Artist',
        album: 'Indie Album',
        duration: Duration(minutes: 3),
        coverUrl: 'https://example.com/c.jpg',
      );

      const customTrack2 = Track(
        id: 'custom-trk-2',
        title: 'Custom Track 2',
        artist: 'Indie Artist 2',
        album: 'Indie Album 2',
        duration: Duration(minutes: 4),
        coverUrl: 'https://example.com/c2.jpg',
      );

      final customPlaylist = Playlist(
        id: 'custom-pl-1',
        title: 'Indie Favorites',
        description: '',
        coverUrl: '',
        tracks: [customTrack1, customTrack2],
        createdAt: DateTime.now(),
      );

      final state = LibraryState(
        playlists: [customPlaylist],
        likedTrackIds: {'custom-trk-1'},
        downloadedPaths: {'custom-trk-2': '/data/downloads/custom-trk-2.m4a'},
      );

      // likedTracks must find custom-trk-1 even though it is not in MusicCatalog.allTracks
      expect(state.likedTracks.length, equals(1));
      expect(state.likedTracks.first.id, equals('custom-trk-1'));
      expect(state.likedTracks.first.title, equals('Custom Track 1'));
      expect(state.likedTracks.first.isLiked, isTrue);

      // downloadedTracks must find custom-trk-2 even though it is not in MusicCatalog.allTracks
      expect(state.downloadedTracks.length, equals(1));
      expect(state.downloadedTracks.first.id, equals('custom-trk-2'));
      expect(state.downloadedTracks.first.title, equals('Custom Track 2'));
      expect(state.downloadedTracks.first.isDownloaded, isTrue);
      expect(state.downloadedTracks.first.localFilePath, equals('/data/downloads/custom-trk-2.m4a'));
    });

    test('downloadedMetadata restores offline tracks not in any active playlist', () {
      const offlineOnlyTrack = Track(
        id: 'offline-only-trk',
        title: 'Disappeared Online Track',
        artist: 'Archived Artist',
        album: 'Lost Album',
        duration: Duration(seconds: 200),
        coverUrl: 'https://example.com/archived.jpg',
        localFilePath: '/data/downloads/offline-only-trk.m4a',
        isDownloaded: true,
      );

      final state = LibraryState(
        playlists: [], // Empty playlists
        downloadedPaths: {'offline-only-trk': '/data/downloads/offline-only-trk.m4a'},
        downloadedMetadata: {'offline-only-trk': offlineOnlyTrack},
      );

      expect(state.downloadedTracks.length, equals(1));
      expect(state.downloadedTracks.first.title, equals('Disappeared Online Track'));
      expect(state.downloadedTracks.first.isDownloaded, isTrue);
      expect(state.downloadedTracks.first.localFilePath, equals('/data/downloads/offline-only-trk.m4a'));
    });

    test('downloadedTracks gracefully creates fallback Track if metadata is completely missing', () {
      final state = LibraryState(
        playlists: [],
        downloadedPaths: {'mystery-track-id': '/data/downloads/mystery-track-id.m4a'},
      );

      expect(state.downloadedTracks.length, equals(1));
      expect(state.downloadedTracks.first.id, equals('mystery-track-id'));
      expect(state.downloadedTracks.first.isDownloaded, isTrue);
      expect(state.downloadedTracks.first.localFilePath, equals('/data/downloads/mystery-track-id.m4a'));
    });
  });
}
