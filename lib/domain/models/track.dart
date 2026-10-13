class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? audioUrl;
  final String coverUrl;
  final String? lyricsLrc;
  final bool isLiked;
  final String? localFilePath;
  final bool isDownloaded;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.audioUrl,
    required this.coverUrl,
    this.lyricsLrc,
    this.isLiked = false,
    this.localFilePath,
    this.isDownloaded = false,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? audioUrl,
    String? coverUrl,
    String? lyricsLrc,
    bool? isLiked,
    String? localFilePath,
    bool? isDownloaded,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      lyricsLrc: lyricsLrc ?? this.lyricsLrc,
      isLiked: isLiked ?? this.isLiked,
      localFilePath: localFilePath ?? this.localFilePath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration_seconds': duration.inSeconds,
      'audio_url': audioUrl,
      'cover_url': coverUrl,
      'lyrics_lrc': lyricsLrc,
      'is_liked': isLiked,
      'local_file_path': localFilePath,
      'is_downloaded': isDownloaded,
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? json['track_name'] ?? json['trackName'] ?? 'Unknown Title').toString();

    final artistRaw = json['artist'] ?? json['artists'] ?? json['artist_name'] ?? json['artistName'] ?? json['subtitle'];
    final artist = parseArtist(artistRaw);

    final albumRaw = json['album'] ?? json['album_name'] ?? json['albumName'];
    final album = parseAlbum(albumRaw, title);

    final duration = json['duration_seconds'] != null
        ? Duration(seconds: (json['duration_seconds'] as num).toInt())
        : (json['duration_ms'] != null
            ? Duration(milliseconds: (json['duration_ms'] as num).toInt())
            : (json['durationMs'] != null
                ? Duration(milliseconds: (json['durationMs'] as num).toInt())
                : parseDuration(json['duration'])));

    String? id = (json['id'] ?? json['track_id'] ?? json['trackId'])?.toString();
    if (id == null || id.isEmpty) {
      final uri = json['uri']?.toString();
      if (uri != null && uri.isNotEmpty) {
        id = uri.replaceFirst('spotify:track:', '');
      } else {
        id = 'trk-${(title + artist).hashCode.abs()}';
      }
    }

    final coverRaw = json['cover_url'] ?? json['coverUrl'] ?? json['image'] ?? json['imageUrl'] ?? json['image_url'] ?? json['cover'] ?? json['images'];
    final coverUrl = parseCoverUrl(coverRaw);

    final audioUrl = (json['audio_url'] ?? json['audioUrl'] ?? json['preview_url'] ?? json['previewUrl'] ?? json['preview'] ?? json['url']) as String?;
    final lyricsLrc = (json['lyrics_lrc'] ?? json['lyricsLrc'] ?? json['lyrics']) as String?;
    final isLiked = (json['is_liked'] ?? json['isLiked'] ?? false) as bool;
    final localFilePath = (json['local_file_path'] ?? json['localFilePath']) as String?;
    final isDownloaded = (json['is_downloaded'] ?? json['isDownloaded'] ?? false) as bool;

    return Track(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      audioUrl: audioUrl,
      coverUrl: coverUrl,
      lyricsLrc: lyricsLrc,
      isLiked: isLiked,
      localFilePath: localFilePath,
      isDownloaded: isDownloaded,
    );
  }

  static String parseArtist(dynamic json) {
    if (json == null) return 'Unknown Artist';
    if (json is String && json.trim().isNotEmpty) return json.trim();
    if (json is List) {
      final names = json.map((a) {
        if (a is String) return a;
        if (a is Map) return (a['name'] ?? a['title'] ?? '').toString();
        return a.toString();
      }).where((s) => s.isNotEmpty).join(', ');
      if (names.isNotEmpty) return names;
    }
    if (json is Map) {
      return (json['name'] ?? json['title'] ?? 'Unknown Artist').toString();
    }
    return 'Unknown Artist';
  }

  static String parseAlbum(dynamic json, String fallback) {
    if (json == null) return fallback;
    if (json is String && json.trim().isNotEmpty) return json.trim();
    if (json is Map) {
      return (json['name'] ?? json['title'] ?? fallback).toString();
    }
    return fallback;
  }

  static String parseCoverUrl(dynamic json) {
    const defaultCover = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80';
    if (json == null) return defaultCover;
    if (json is String && json.trim().isNotEmpty) return json.trim();
    if (json is List && json.isNotEmpty) {
      final first = json.first;
      if (first is String) return first;
      if (first is Map) return (first['url'] ?? first['link'] ?? defaultCover).toString();
    }
    if (json is Map) {
      return (json['url'] ?? json['link'] ?? defaultCover).toString();
    }
    return defaultCover;
  }

  static Duration parseDuration(dynamic value) {
    if (value == null) return const Duration(seconds: 180);
    if (value is int) {
      if (value > 10000) return Duration(milliseconds: value);
      return Duration(seconds: value);
    }
    if (value is double) {
      if (value > 10000) return Duration(milliseconds: value.toInt());
      return Duration(seconds: value.toInt());
    }
    if (value is String) {
      final trimmed = value.trim();
      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        final parsed = int.tryParse(trimmed) ?? 180;
        return parsed > 10000 ? Duration(milliseconds: parsed) : Duration(seconds: parsed);
      }
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return Duration(minutes: m, seconds: s);
      } else if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        return Duration(hours: h, minutes: m, seconds: s);
      }
    }
    return const Duration(seconds: 180);
  }
}
