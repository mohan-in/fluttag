import 'package:fluttag/notifiers/folder_tree_notifier.dart';
import 'package:fluttag/screens/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Landing screen shown at app launch with a prominent folder selection button.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Fluttag',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ID3 Tag Editor',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => _selectFolder(context),
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Root Folder'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFolder(BuildContext context) async {
    final folderNotifier = context.read<FolderTreeNotifier>();
    await folderNotifier.selectRootFolder();

    if (!context.mounted) {
      return;
    }

    if (folderNotifier.rootNode != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
      );
    }
  }
}
