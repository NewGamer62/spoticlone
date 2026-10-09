# Recon map: Spotify (Windows Desktop & Android Mobile)

Scope: Music player core loop, home discovery, instant search, personal library, playlists, lyrics, queue management, and responsive layouts.
For: Personal portfolio and daily music streaming without subscription constraints.
Date: 2026-10-09

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | Spotify Web Player | https://open.spotify.com | UI layout, desktop 3-pane architecture, navigation patterns |
| 2 | Spotify Android App | Google Play Store / APK | Mobile navigation bar, sticky mini-player, full-screen player gestures |
| 3 | Spotify Desktop (Windows) | Windows Store / Desktop client | Desktop media keys, window layout, right side queue panel |
| 4 | Spotify Design System | https://spotify.design | Color palette (#121212, #1DB954), typography, circular play buttons |

## Core loop

Discover, search, queue, and seamlessly listen to songs with rich metadata and responsive playback controls across Desktop and Mobile.

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Home / Browse | `/home` (default) | Show featured mixes, recently played, top daily hits | HeroBanner, MediaShelfGrid, QuickAccessGrid | loading, filled, error |
| S02 | Search & Explore | `/search` | Search songs, artists, albums, or browse by genre tiles | SearchBar, GenreCategoryGrid, SearchResultsList | empty, typing, filled, not-found |
| S03 | Your Library | `/library` | Manage liked tracks, custom playlists, and pinned items | FilterChips, LibraryListView, CreatePlaylistBtn | empty, filled |
| S04 | Playlist / Album View | `/playlist/:id` | View tracklist, duration, creator, and play in order/shuffle | PlaylistHeader, TrackTable/List, PlayShuffleFab | loading, filled |
| S05 | Artist Profile | `/artist/:id` | View artist top tracks, discography, and biography | ArtistHero, TopTracksList, AlbumHorizontalScroll | loading, filled |
| S06 | Now Playing & Lyrics | `/now-playing` | Fullscreen immersive player view, synchronized lyrics | AlbumArtCover, WaveScrubber, LyricsScrollPanel | playing, paused, lyrics-sync |
| S07 | Playback Queue | `/queue` | View current track, next up queue, and history | QueueTrackList, ReorderDragHandle, ClearQueueBtn | empty, active |
| S08 | Settings & Storage | `/settings` | Audio stream quality, local cache, theme, import/export | AudioQualityPicker, CacheClearButton, ExportJsonBtn | default |

## Flows

```
F01 Search & Play a Track
    S02 Search -> Type query -> Tap result track -> Audio stream starts in S06 / PlayerBar
    happy path clicks: 3
    edge: stream loading delay, network timeout, rate limiting fallback

F02 Queue Management & Shuffle
    S06 / PlayerBar -> Open S07 Queue -> Drag to reorder / Tap next track
    happy path clicks: 2
    edge: empty queue, repeat mode toggled

F03 Create Playlist & Add Favorites
    S01/S02/S06 -> Tap Heart (Like) icon -> Track saved to S03 Liked Songs -> Tap Add to Playlist
    happy path clicks: 2
    edge: duplicate song in playlist warning

F04 Responsive Transition Desktop <-> Mobile
    Windows (Window resize) or Android device orientation / form factor
    Desktop (Sidebar + 3 panes) <-> Mobile (BottomNavBar + MiniPlayer)
    happy path clicks: 0 (automatic adaptive layout)

F05 Lyrics Synchronization & Sing-Along
    S06 Player -> Tap Lyrics icon -> Fullscreen karaoke scroll
    happy path clicks: 1
    edge: lyrics unavailable for current song
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| DesktopPlayerBar | Standard 3-part (Track info, Controls, Volume/Addons) | playing, paused, buffering, mute, shuffle, repeat | Windows S01-S08 |
| MobileMiniPlayer | Floating card above bottom bar | playing, paused, buffering, swipe-to-dismiss | Android S01-S05 |
| MobileBottomNav | 3 items (Home, Search, Library) | active, inactive | Android S01-S05 |
| DesktopSidebar | Pinned top (Home, Search) + Bottom Library list | expanded, collapsed | Windows S01-S08 |
| TrackTile | List row (number, title, artist, duration, like) | default, hover, active-playing, selected | S02, S03, S04, S05, S07 |
| MediaCard | Square cover with bottom title and floating green play button | default, hover, pressed | S01, S02, S03 |
| ScrubProgressBar | Desktop slider / Mobile wave scrubber | dragging, hover-time-preview, normal | S06, PlayerBar |
| LikeButton | Heart icon | liked (green/filled), unliked (outline) | S04, S06, PlayerBar |

## Inferred data model

```
Track           id, title, artist, album, duration_seconds, audio_stream_url, cover_url, lyrics_lrc
                evidence: S01, S02, S04, S06
                confidence: high

Playlist        id, title, description, cover_url, is_custom, created_at
                evidence: S03, S04
                confidence: high

PlaylistTrack   playlist_id, track_id, position, added_at
                evidence: S04
                confidence: high

FavoriteTrack   track_id, added_at
                evidence: S03, S06
                confidence: high

PlayHistory     id, track_id, played_at
                evidence: S01, S07
                confidence: high
```

Relationships:
- Playlist 1-n PlaylistTrack n-1 Track
- User 1-n FavoriteTrack n-1 Track
- User 1-n PlayHistory n-1 Track

## Feature matrix

See `features.csv`.
- Must: 10
- Should: 6
- Could: 3
- Skip: 2

## Out of scope (cannot or should not be cloned)

- Proprietary Spotify DRM Widevine audio streams (replaced with open audio stream extraction via YouTube / Piped API).
- Spotify Friend Activity live server mesh (requires real-time closed social graph).
- Paid in-app subscriptions and payment gateways (clone is 100% free and open-source).

## Size

Screens: 8. Flows: 5. Entities: 5.
Hard parts: Cross-platform background audio session & controls (Windows System Media Controls + Android MediaNotification), synchronized lyrics parser, seamless adaptive layout between desktop 3-pane and mobile bottom-sheet.
Size: M.
