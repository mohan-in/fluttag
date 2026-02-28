import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:fluttag/data/file_system_repository.dart';
import 'package:fluttag/domain/folder_node.dart';

/// Manages the folder tree state and current folder selection.
class FolderTreeNotifier extends ChangeNotifier {
  FolderTreeNotifier({required FileSystemRepository fileSystemRepository})
    : _fileSystemRepository = fileSystemRepository;

  final FileSystemRepository _fileSystemRepository;

  FolderNode? _rootNode;
  FolderNode? get rootNode => _rootNode;

  String? _selectedPath;
  String? get selectedPath => _selectedPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Opens a folder picker dialog and loads the folder tree.
  Future<bool> selectRootFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Music Folder',
    );

    if (result == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    _rootNode = await _fileSystemRepository.buildFolderTree(result);
    _rootNode!.isExpanded = true;
    _selectedPath = result;
    _isLoading = false;
    notifyListeners();

    return true;
  }

  /// Toggles the expanded state of a folder node.
  void toggleExpand(FolderNode node) {
    node.isExpanded = !node.isExpanded;
    notifyListeners();
  }

  /// Selects a folder by path.
  void selectFolder(String path) {
    _selectedPath = path;
    notifyListeners();
  }
}
