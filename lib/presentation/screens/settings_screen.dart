import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _exportJson(BuildContext context, WidgetRef ref) async {
    final jsonStr = await ref.read(libraryProvider.notifier).exportPlaylistsAsJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlists JSON copied to clipboard!')),
      );
    }
  }

  void _importJson(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Import Playlists JSON', style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: textController,
          maxLines: 8,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'Paste playlists JSON here...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(),
          ),
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
            onPressed: () async {
              try {
                await ref.read(libraryProvider.notifier).importPlaylistsFromJson(textController.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlists successfully imported!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid JSON format')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(navigationProvider.notifier).setTab(AppTab.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Audio Quality Section
          const Text(
            'Audio Streaming',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Streaming Quality', style: TextStyle(color: AppColors.text)),
            subtitle: const Text('High (320 kbps uncompressed)', style: TextStyle(color: AppColors.textMuted)),
            trailing: const Icon(Icons.check, color: AppColors.accent),
          ),
          const Divider(color: AppColors.border),

          // Backup & Restore Section
          const SizedBox(height: 16),
          const Text(
            'Data & Portability',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_upload_outlined, color: AppColors.text),
            title: const Text('Export Playlists (JSON)', style: TextStyle(color: AppColors.text)),
            subtitle: const Text('Copy backup of all your custom playlists to clipboard', style: TextStyle(color: AppColors.textMuted)),
            onTap: () => _exportJson(context, ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_download_outlined, color: AppColors.text),
            title: const Text('Import Playlists (JSON)', style: TextStyle(color: AppColors.text)),
            subtitle: const Text('Restore playlists from JSON format', style: TextStyle(color: AppColors.textMuted)),
            onTap: () => _importJson(context, ref),
          ),
          const Divider(color: AppColors.border),

          // About Section
          const SizedBox(height: 16),
          const Text(
            'About SpotiClone',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Version', style: TextStyle(color: AppColors.text)),
            subtitle: Text('1.0.0 (Clean-Room Rebuild)', style: TextStyle(color: AppColors.textMuted)),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Architecture', style: TextStyle(color: AppColors.text)),
            subtitle: Text('Flutter Native Windows & Android • Local-First Storage • Open Stream Engine', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
