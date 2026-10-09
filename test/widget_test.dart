import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spoticlone/domain/models/lyrics_line.dart';
import 'package:spoticlone/domain/models/track.dart';
import 'package:spoticlone/domain/models/playlist.dart';
import 'package:spoticlone/main.dart';

void main() {
  test('LyricsLine parser parses standard LRC format correctly', () {
    const lrc = '''[00:05.12] First line of song
[00:15.30] Second line of song
[01:02.00] Third line of song''';

    final lines = LyricsLine.parseLrc(lrc);
    expect(lines.length, equals(3));
    expect(lines[0].text, equals('First line of song'));
    expect(lines[0].timestamp.inSeconds, equals(5));
    expect(lines[1].text, equals('Second line of song'));
    expect(lines[1].timestamp.inSeconds, equals(15));
    expect(lines[2].text, equals('Third line of song'));
    expect(lines[2].timestamp.inSeconds, equals(62));
  });

  test('Track model serialization and copyWith work', () {
    const track = Track(
      id: 'test-1',
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      duration: Duration(minutes: 3),
      coverUrl: 'https://example.com/cover.jpg',
    );

    final json = track.toJson();
    final deserialized = Track.fromJson(json);

    expect(deserialized.id, equals('test-1'));
    expect(deserialized.title, equals('Test Song'));
    expect(deserialized.duration.inSeconds, equals(180));

    final updated = track.copyWith(title: 'Updated Title', isLiked: true);
    expect(updated.title, equals('Updated Title'));
    expect(updated.isLiked, isTrue);
  });

  test('Playlist model calculates total duration correctly', () {
    const track1 = Track(
      id: '1',
      title: 'T1',
      artist: 'A1',
      album: 'Alb1',
      duration: Duration(seconds: 120),
      coverUrl: '',
    );
    const track2 = Track(
      id: '2',
      title: 'T2',
      artist: 'A2',
      album: 'Alb2',
      duration: Duration(seconds: 180),
      coverUrl: '',
    );

    final playlist = Playlist(
      id: 'pl-1',
      title: 'Mix',
      description: 'Desc',
      coverUrl: '',
      tracks: [track1, track2],
      createdAt: DateTime.now(),
    );

    expect(playlist.totalDuration.inSeconds, equals(300));
  });

  test('Track model handles offline download fields correctly', () {
    const track = Track(
      id: 'trk-offline',
      title: 'Offline Song',
      artist: 'Artist',
      album: 'Album',
      duration: Duration(seconds: 150),
      coverUrl: '',
      localFilePath: '/path/to/downloaded.mp3',
      isDownloaded: true,
    );

    final json = track.toJson();
    final restored = Track.fromJson(json);

    expect(restored.isDownloaded, isTrue);
    expect(restored.localFilePath, equals('/path/to/downloaded.mp3'));
  });

  testWidgets('SpotiClone boots up in ProviderScope and renders header', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SpotiCloneApp(),
      ),
    );

    await tester.pump();
    expect(find.text('SpotiClone'), findsOneWidget);
  });
}
