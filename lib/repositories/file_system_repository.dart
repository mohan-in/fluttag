import 'dart:io';

import 'package:fluttag/models/folder_node.dart';

/// Repository for file system operations.
class FileSystemRepository {
  /// Audio file extensions to look for.
  static const List<String> _audioExtensions = [
    '.mp3',
    '.m4a',
    '.opus',
    '.flac',
    '.ogg',
    '.aac',
    '.wma',
    '.wav',
  ];

  /// Builds a recursive folder tree starting from [rootPath].
  ///
  /// Only includes directories (not files) in the tree.
  Future<FolderNode> buildFolderTree(String rootPath) async {
    final dir = Directory(rootPath);
    final node = FolderNode(
      path: dir.path,
      name: dir.path.split(Platform.pathSeparator).last,
    );

    try {
      final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

      for (final entity in entities) {
        if (entity is Directory) {
          final childName = entity.path.split(Platform.pathSeparator).last;
          // Skip hidden directories.
          if (childName.startsWith('.')) {
            continue;
          }
          final childNode = await buildFolderTree(entity.path);
          node.children.add(childNode);
        }
      }
    } on FileSystemException {
      // Silently skip directories we can't read (permissions, etc.).
    }

    return node;
  }

  /// Lists all audio file paths in [directoryPath] (non-recursive).
  Future<List<String>> listAudioFiles(String directoryPath) async {
    final dir = Directory(directoryPath);
    final audioPaths = <String>[];

    try {
      final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

      for (final entity in entities) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          final lastDotIndex = name.lastIndexOf('.');
          if (lastDotIndex != -1) {
            final extension = name.substring(lastDotIndex).toLowerCase();
            if (_audioExtensions.contains(extension)) {
              audioPaths.add(entity.path);
            }
          }
        }
      }
    } on FileSystemException {
      // Skip unreadable directories.
    }

    return audioPaths;
  }
}
