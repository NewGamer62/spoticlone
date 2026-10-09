import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/audio/youtube_audio_resolver.dart';
import '../../data/music_catalog.dart';
import '../../domain/models/track.dart';

class SearchState {
  final String query;
  final List<Track> results;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
  });

  SearchState copyWith({
    String? query,
    List<Track>? results,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(query: '', results: [], isLoading: false);
      return;
    }

    state = state.copyWith(query: trimmed, isLoading: true);

    // Filter local catalog first
    final localMatches = MusicCatalog.allTracks.where((t) {
      final q = trimmed.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q) ||
          t.album.toLowerCase().contains(q);
    }).toList();

    try {
      // Also fetch live YouTube Music results for boundless discovery
      final ytMatches = await YoutubeAudioResolver.searchYoutubeTracks(trimmed);
      final combined = [...localMatches, ...ytMatches];
      state = state.copyWith(results: combined, isLoading: false);
    } catch (_) {
      state = state.copyWith(results: localMatches, isLoading: false);
    }
  }

  void clearSearch() {
    state = const SearchState();
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
