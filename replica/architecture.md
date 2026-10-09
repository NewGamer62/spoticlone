# Architecture: SpotiClone (Clean-Room Rebuild of Spotify)

## Stack

| layer | choice | why |
| --- | --- | --- |
| Client Framework | Flutter (Dart 3.x) | Single codebase compiled natively for Windows (Win32/C++) and Android, 60/120fps UI, direct native access. |
| State Management | Flutter Riverpod | Declarative, decoupled, robust state management with dependency injection and testability. |
| Audio Engine | `just_audio` + `audio_service` | Low-latency audio playback, background service, lock-screen controls, media key integration. |
| Audio Source | `youtube_explode_dart` + Open Metadata | High quality audio streams extracted on-the-fly without commercials or account requirements. |
| Local Database | Drift (SQLite) + `sqlite3_flutter_libs` | High performance, typed relational SQL on both Windows and Android, offline-first. |
| Design System | Spotify Design Tokens | Dark theme (#121212), Spotify Green accent (#1DB954), 8px grid system, WCAG AA verified. |

## Schema

Tables: 5. Access rules: Local-First on-device storage with optional remote sync export/import.

```sql
-- See replica/schema.sql
```

## API / Internal Services

| service / method | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| `AudioService.play(track)` | Streams audio url or local cache | Player | `Track` | void / stream state | F01, F02 |
| `SearchService.search(query)` | Fetches matching songs/artists | User | `String` | `List<Track>` | F01 |
| `LibraryRepository.toggleLike(id)` | Likes/unlikes track in SQLite | User | `Track` | `bool` | F03 |
| `PlaylistRepository.create(name)` | Creates new local playlist | User | `String` | `Playlist` | F03 |
| `QueueController.addNext(track)` | Enqueues track for playback | User | `Track` | `List<Track>` | F02 |

Webhooks in: none (pure client local-first app).
Webhooks out: none.
Background services: Android Foreground Audio Service (`AudioService`) running with notification player controls and media session for Windows taskbar/hardware keys.

## The parts that bite

- **Cross-platform Audio Lifecycle** : Android pauses audio if lifecycle and background permissions aren't properly managed in Foreground Service; Windows requires hardware media transport handling.
- **Network Glitches & Stream Fallback** : Stream URLs can expire after inactivity; audio manager must refresh stream URL on resume if playback stalled.
- **Large Lists & Virtualization** : Playlists with hundreds of songs require `ListView.builder` with recycling to keep memory under 150MB.

## Build order

1. **Vertical slice** : Shell responsive (Sidebar/BottomNav), fake audio track, play/pause working.
2. **Must-haves** :
   - Audio Engine (`just_audio` integration with seek, duration, status).
   - Search & Exploration (mock/live stream query).
   - Local Database (Drift SQLite for Favorites and Playlists).
   - Responsive layouts (Windows 3-pane desktop layout vs Mobile scaffold).
3. **Should-haves** :
   - Synchronized lyrics parser (LRC format).
   - Volume slider & repeat/shuffle modes.
   - Queue inspector.
4. **Fixes from replica-entrepreneur** :
   - JSON export/import of playlists.
   - Zero commercial interruptions and no forced shuffle restrictions.
