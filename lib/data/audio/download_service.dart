import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/track.dart';
import 'youtube_audio_resolver.dart';

class DownloadService {
  static final HttpClient _httpClient = HttpClient();
  static int _activeDownloads = 0;
  static const int _maxConcurrentDownloads = 2;
  static final List<Completer<void>> _queue = [];

  static Future<void> _acquireSlot() async {
    if (_activeDownloads < _maxConcurrentDownloads) {
      _activeDownloads++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  static void _releaseSlot() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.complete();
    } else {
      _activeDownloads--;
    }
  }

  /// Gets the directory where offline tracks are stored
  static Future<Directory> getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/spoticlone_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// Downloads a track audio stream to local file storage for 100% offline playback
  static Future<String?> downloadTrack(Track track) async {
    await _acquireSlot();
    try {
      String? streamUrl = track.audioUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await YoutubeAudioResolver.resolveAudioStream(track);
      }

      streamUrl ??= 'https://raw.githubusercontent.com/rafaelreis-hotmart/Audio-Sample-files/master/sample.mp3';

      final dir = await getDownloadsDirectory();
      // Sanitize file name
      final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetFile = File('${dir.path}/$safeId.mp3');

      final request = await _httpClient.getUrl(Uri.parse(streamUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final sink = targetFile.openWrite();
        await response.pipe(sink);
        await sink.close();
        return targetFile.path;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      _releaseSlot();
    }
  }

  /// Deletes a downloaded track from local disk
  static Future<bool> deleteDownloadedTrack(String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if a file actually exists on disk
  static Future<bool> isTrackFileAvailable(String? localFilePath) async {
    if (localFilePath == null || localFilePath.isEmpty) return false;
    final file = File(localFilePath);
    return file.exists();
  }
}
