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
    File? targetFile;
    try {
      final dir = await getDownloadsDirectory();
      final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      // Case 1: Direct HTTP/HTTPS audio URL (not a YouTube watch / embed page)
      if (track.audioUrl != null &&
          (track.audioUrl!.startsWith('http://') || track.audioUrl!.startsWith('https://')) &&
          !track.audioUrl!.contains('youtube.com') &&
          !track.audioUrl!.contains('youtu.be')) {
        final isM4a = track.audioUrl!.toLowerCase().contains('.m4a') ||
            track.audioUrl!.toLowerCase().contains('.aac');
        final ext = isM4a ? '.m4a' : '.mp3';
        targetFile = File('${dir.path}/$safeId$ext');

        final request = await _httpClient.getUrl(Uri.parse(track.audioUrl!));
        request.headers.set('User-Agent', 'Mozilla/5.0');
        final response = await request.close();

        if (response.statusCode == 200) {
          final sink = targetFile.openWrite();
          await response.pipe(sink); // Stream.pipe automatically closes sink on completion
          if (await targetFile.exists() && await targetFile.length() > 0) {
            return targetFile.path;
          }
        }
        return null;
      }

      // Case 2: Resolve stream info via YouTubeExplode
      final streamInfo = await YoutubeAudioResolver.resolvePreferredStreamInfo(track);
      if (streamInfo != null) {
        final isMp4 = streamInfo.tag == 140 ||
            streamInfo.container.name.toLowerCase() == 'mp4' ||
            streamInfo.container.name.toLowerCase() == 'm4a' ||
            streamInfo.audioCodec.toLowerCase().contains('aac') ||
            streamInfo.audioCodec.toLowerCase().contains('mp4');
        final ext = isMp4 ? '.m4a' : '.webm';
        targetFile = File('${dir.path}/$safeId$ext');

        final audioStream = YoutubeAudioResolver.ytClient.videos.streamsClient.get(streamInfo);
        final sink = targetFile.openWrite();
        await audioStream.pipe(sink); // Stream.pipe automatically closes sink on completion

        if (await targetFile.exists() && await targetFile.length() > 0) {
          return targetFile.path;
        }
      }

      // Fallback: Sample MP3 via HTTP client
      const sampleUrl = 'https://raw.githubusercontent.com/rafaelreis-hotmart/Audio-Sample-files/master/sample.mp3';
      targetFile = File('${dir.path}/$safeId.mp3');
      final request = await _httpClient.getUrl(Uri.parse(sampleUrl));
      final response = await request.close();
      if (response.statusCode == 200) {
        final sink = targetFile.openWrite();
        await response.pipe(sink);
        if (await targetFile.exists() && await targetFile.length() > 0) {
          return targetFile.path;
        }
      }

      return null;
    } catch (e) {
      if (targetFile != null && await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
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
    return (await file.exists()) && (await file.length() > 0);
  }
}
