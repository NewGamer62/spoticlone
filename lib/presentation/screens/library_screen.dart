import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/playlist.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  void _showCreatePlaylistDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Create Playlist', style: TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                labelText: 'Playlist name',
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
            ),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                ref.read(libraryProvider.notifier).createPlaylist(title, descController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showImportSpotifyDialog() async {
    final creds = await ref.read(libraryProvider.notifier).getSpotifyCredentials();
    final urlController = TextEditingController();
    final clientIdController = TextEditingController(text: creds['client_id']);
    final secretController = TextEditingController(text: creds['client_secret']);
    bool isLoading = false;
    bool showDevApi = false;
    String? errorMessage;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Row(
            children: const [
              Icon(Icons.sync_alt, color: AppColors.accent),
              SizedBox(width: 10),
              Text('Importer une playlist', style: TextStyle(color: AppColors.text, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collez le lien de votre playlist publique depuis Spotify, YouTube / YouTube Music ou Deezer. Détection 100% automatique et sans inscription.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(
                      labelText: 'Lien Spotify, YouTube ou Deezer',
                      hintText: 'https://open.spotify.com/... ou https://youtube.com/...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      labelStyle: TextStyle(color: AppColors.accent),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        showDevApi = !showDevApi;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            showDevApi ? Icons.arrow_drop_down : Icons.arrow_right,
                            color: AppColors.textMuted,
                          ),
                          const Text(
                            'Options avancées (Clés API Spotify Developer)',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showDevApi) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: clientIdController,
                      style: const TextStyle(color: AppColors.text, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Client ID (Optionnel)',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: secretController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.text, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Client Secret (Optionnel)',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final url = urlController.text.trim();
                      final cid = clientIdController.text.trim();
                      final csec = secretController.text.trim();

                      if (url.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Veuillez coller un lien Spotify.';
                        });
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final Playlist importedPl;
                        if (cid.isNotEmpty && csec.isNotEmpty) {
                          importedPl = await ref.read(libraryProvider.notifier).importSpotifyPlaylist(
                                playlistInput: url,
                                clientId: cid,
                                clientSecret: csec,
                              );
                        } else {
                          importedPl = await ref.read(libraryProvider.notifier).importPlaylistFromAnyPlatform(url);
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ref.read(navigationProvider.notifier).openPlaylist(importedPl);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Playlist "${importedPl.title}" importée (${importedPl.tracks.length} titres) !'),
                              backgroundColor: AppColors.surfaceHighlight,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: const Text('Importer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final likedTracks = library.likedTracks;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header with Title and Create Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Library',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.text,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        icon: const Icon(Icons.sync_alt, size: 18, color: AppColors.accent),
                        label: const Text('Importer Playlist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        onPressed: _showImportSpotifyDialog,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Create Playlist',
                        icon: const Icon(Icons.add, color: AppColors.text, size: 28),
                        onPressed: _showCreatePlaylistDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pinned "Liked Songs" and "Downloaded Songs"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  // Liked Songs Tile
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final likedPlaylist = Playlist(
                            id: 'pl-liked',
                            title: 'Liked Songs',
                            description: 'Your personal collection of saved favorite tracks.',
                            coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
                            tracks: likedTracks,
                            isCustom: false,
                            createdAt: DateTime.now(),
                          );
                          ref.read(navigationProvider.notifier).openPlaylist(likedPlaylist);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(Icons.favorite, color: Color(0xFF450AF5), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Liked Songs',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${likedTracks.length} songs',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Downloaded (Offline) Tile
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final downloaded = library.downloadedTracks;
                          final downloadedPlaylist = Playlist(
                            id: 'pl-downloaded',
                            title: 'Downloaded Songs',
                            description: 'Saved on device for 100% offline listening without internet.',
                            coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
                            tracks: downloaded,
                            isCustom: false,
                            createdAt: DateTime.now(),
                          );
                          ref.read(navigationProvider.notifier).openPlaylist(downloadedPlaylist);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006450), Color(0xFF1DB954)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(Icons.arrow_circle_down, color: Color(0xFF006450), size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Downloaded',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${library.downloadedTracks.length} offline',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // All Playlists
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final pl = library.playlists[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        pl.coverUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.music_note, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    title: Text(
                      pl.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Playlist • ${pl.tracks.length} tracks',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    trailing: pl.isCustom
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                            onPressed: () {
                              // Delete custom playlist
                            },
                          )
                        : null,
                    onTap: () {
                      ref.read(navigationProvider.notifier).openPlaylist(pl);
                    },
                  );
                },
                childCount: library.playlists.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
