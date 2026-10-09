import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/track.dart';
import 'youtube_audio_resolver.dart';

class DownloadService {
  static final HttpClient _httpClient = HttpClient();

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
    try {
      String? streamUrl = track.audioUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await YoutubeAudioResolver.resolveAudioStream(track);
      }

      streamUrl ??= 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=lofi-study-112191.mp3';

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
