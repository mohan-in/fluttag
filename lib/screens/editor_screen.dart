import 'dart:async';

import 'package:fluttag/notifiers/audio_file_list_notifier.dart';
import 'package:fluttag/notifiers/column_settings_notifier.dart';
import 'package:fluttag/notifiers/folder_tree_notifier.dart';
import 'package:fluttag/notifiers/tag_editor_notifier.dart';
import 'package:fluttag/widgets/audio_file_list_pane.dart';
import 'package:fluttag/widgets/folder_tree_pane.dart';
import 'package:fluttag/widgets/tag_editor_pane.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 3-pane editor screen: folder tree, file list, tag editor.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  /// Tracks the last folder path we loaded files for.
  String? _lastLoadedFolder;

  @override
  void initState() {
    super.initState();
    // Load files for the initially selected folder.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final folderNotifier = context.read<FolderTreeNotifier>();
      final selectedPath = folderNotifier.selectedPath;
      if (selectedPath != null) {
        _lastLoadedFolder = selectedPath;
        unawaited(
          context.read<AudioFileListNotifier>().loadFiles(selectedPath),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // React to folder selection changes to load files.
    final selectedFolder = context.select<FolderTreeNotifier, String?>(
      (n) => n.selectedPath,
    );
    final isFolderLoading = context.select<FolderTreeNotifier, bool>(
      (n) => n.isLoading,
    );

    if (selectedFolder != null &&
        !isFolderLoading &&
        selectedFolder != _lastLoadedFolder) {
      _lastLoadedFolder = selectedFolder;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            context.read<AudioFileListNotifier>().loadFiles(selectedFolder),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.music_note, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Fluttag'),
          ],
        ),
        actions: [_CopyFilenameToTitleButton(), _ColumnMenuButton()],
      ),
      body: Row(
        children: [
          // Left pane: Folder tree.
          SizedBox(
            width: 250,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: const FolderTreePane(),
            ),
          ),
          // Middle pane: File list.
          const Expanded(flex: 5, child: AudioFileListPane()),
          // Right pane: Tag editor.
          SizedBox(
            width: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: const TagEditorPane(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnMenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final columnNotifier = context.watch<ColumnSettingsNotifier>();

    return PopupMenuButton<FileColumn>(
      icon: const Icon(Icons.view_column),
      tooltip: 'Column visibility',
      onSelected: columnNotifier.toggleColumn,
      itemBuilder: (context) {
        return FileColumn.values.map((column) {
          return CheckedPopupMenuItem<FileColumn>(
            value: column,
            checked: columnNotifier.visibility[column] ?? false,
            child: Text(column.label),
          );
        }).toList();
      },
    );
  }
}

class _CopyFilenameToTitleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tagNotifier = context.watch<TagEditorNotifier>();
    final hasFiles = tagNotifier.editingFiles.isNotEmpty;

    return IconButton(
      icon: const Icon(Icons.drive_file_rename_outline),
      tooltip: 'Copy filename to title (all selected)',
      onPressed: hasFiles
          ? () {
              for (final file in tagNotifier.editingFiles) {
                final name = file.fileName.contains('.')
                    ? file.fileName.substring(0, file.fileName.lastIndexOf('.'))
                    : file.fileName;
                file.title = name;
              }
              tagNotifier.notifyManually();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Copied filename → title for '
                    '${tagNotifier.editingFiles.length} file(s)',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
    );
  }
}
