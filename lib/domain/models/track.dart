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
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 180),
      audioUrl: json['audio_url'] as String?,
      coverUrl: json['cover_url'] as String? ?? '',
      lyricsLrc: json['lyrics_lrc'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
      localFilePath: json['local_file_path'] as String?,
      isDownloaded: json['is_downloaded'] as bool? ?? false,
    );
  }
}
