import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/playlist.dart';

enum AppTab { home, search, library, playlistDetail, queue, lyrics, settings }

class NavigationState {
  final AppTab currentTab;
  final Playlist? selectedPlaylist;
  final bool isRightPanelOpen;

  const NavigationState({
    this.currentTab = AppTab.home,
    this.selectedPlaylist,
    this.isRightPanelOpen = false,
  });

  NavigationState copyWith({
    AppTab? currentTab,
    Playlist? selectedPlaylist,
    bool? isRightPanelOpen,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      selectedPlaylist: selectedPlaylist ?? this.selectedPlaylist,
      isRightPanelOpen: isRightPanelOpen ?? this.isRightPanelOpen,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() => const NavigationState();

  void setTab(AppTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void openPlaylist(Playlist playlist) {
    state = state.copyWith(
      currentTab: AppTab.playlistDetail,
      selectedPlaylist: playlist,
    );
  }

  void toggleRightPanel() {
    state = state.copyWith(isRightPanelOpen: !state.isRightPanelOpen);
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);
