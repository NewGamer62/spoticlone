import 'track.dart';

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<Track> tracks;
  final bool isCustom;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.tracks,
    this.isCustom = true,
    required this.createdAt,
  });

  Duration get totalDuration {
    return tracks.fold(Duration.zero, (prev, track) => prev + track.duration);
  }

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<Track>? tracks,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      tracks: tracks ?? this.tracks,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'is_custom': isCustom,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      tracks: (json['tracks'] as List<dynamic>? ?? [])
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList(),
      isCustom: json['is_custom'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
