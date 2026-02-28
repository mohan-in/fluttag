import 'dart:async';

import 'package:fluttag/models/folder_node.dart';
import 'package:fluttag/notifiers/folder_tree_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Left pane: displays the folder tree for navigation.
class FolderTreePane extends StatelessWidget {
  const FolderTreePane({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<FolderTreeNotifier>();
    final theme = Theme.of(context);

    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.rootNode == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No folder selected',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _FolderTreeHeader(rootPath: notifier.rootNode!.name),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [_buildNode(context, notifier.rootNode!, 0)],
          ),
        ),
      ],
    );
  }

  Widget _buildNode(BuildContext context, FolderNode node, int depth) {
    final notifier = context.read<FolderTreeNotifier>();
    final isSelected = notifier.selectedPath == node.path;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          child: InkWell(
            onTap: () => notifier.selectFolder(node.path),
            child: Padding(
              padding: EdgeInsets.only(
                left: 8.0 + (depth * 16.0),
                top: 6,
                bottom: 6,
                right: 8,
              ),
              child: Row(
                children: [
                  if (node.children.isNotEmpty)
                    InkWell(
                      onTap: () => notifier.toggleExpand(node),
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(
                        node.isExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 4),
                  Icon(
                    node.isExpanded ? Icons.folder_open : Icons.folder,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (node.isExpanded)
          ...node.children.map(
            (child) => _buildNode(context, child, depth + 1),
          ),
      ],
    );
  }
}

class _FolderTreeHeader extends StatelessWidget {
  const _FolderTreeHeader({required this.rootPath});

  final String rootPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.library_music, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rootPath,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, size: 18),
            tooltip: 'Change root folder',
            onPressed: () {
              unawaited(context.read<FolderTreeNotifier>().selectRootFolder());
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
