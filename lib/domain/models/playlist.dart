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
    final title = (json['title'] ?? json['name'] ?? json['playlist_name'] ?? json['playlistName'] ?? 'Imported Playlist').toString();

    String id = (json['id'] ?? json['playlist_id'] ?? json['playlistId'])?.toString() ?? '';
    if (id.isEmpty) {
      final uri = json['uri']?.toString();
      if (uri != null && uri.isNotEmpty) {
        id = uri.replaceFirst('spotify:playlist:', '');
      } else {
        id = 'pl-${title.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9_-]'), '_')}';
      }
    }

    final description = (json['description'] ?? json['desc'] ?? json['subtitle'] ?? '').toString();

    final coverRaw = json['cover_url'] ??
        json['coverUrl'] ??
        json['image'] ??
        json['imageUrl'] ??
        json['image_url'] ??
        json['picture_xl'] ??
        json['picture'] ??
        json['cover'] ??
        json['images'];

    final rawTracks = json['tracks'] ?? json['trackList'] ?? json['items'] ?? json['data'] ?? json['songs'];
    final List<dynamic> trackList;
    if (rawTracks is List<dynamic>) {
      trackList = rawTracks;
    } else if (rawTracks is Map<String, dynamic> && rawTracks['data'] is List<dynamic>) {
      trackList = rawTracks['data'] as List<dynamic>;
    } else if (rawTracks is Map<String, dynamic> && rawTracks['items'] is List<dynamic>) {
      trackList = rawTracks['items'] as List<dynamic>;
    } else {
      trackList = [];
    }

    final tracks = <Track>[];
    for (final item in trackList) {
      if (item is Map<String, dynamic>) {
        final trackData = item.containsKey('track') && item['track'] is Map<String, dynamic>
            ? item['track'] as Map<String, dynamic>
            : item;
        tracks.add(Track.fromJson(trackData));
      }
    }

    String coverUrl = Track.parseCoverUrl(coverRaw);
    if ((coverRaw == null || coverUrl == Track.defaultCoverUrl) &&
        tracks.isNotEmpty &&
        tracks.first.coverUrl.isNotEmpty &&
        tracks.first.coverUrl != Track.defaultCoverUrl) {
      coverUrl = tracks.first.coverUrl;
    }

    final createdAt = json['created_at'] != null || json['createdAt'] != null
        ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
        : DateTime.now();

    final isCustom = (json['is_custom'] ?? json['isCustom'] ?? true) as bool;

    return Playlist(
      id: id,
      title: title,
      description: description,
      coverUrl: coverUrl,
      tracks: tracks,
      isCustom: isCustom,
      createdAt: createdAt,
    );
  }
}
