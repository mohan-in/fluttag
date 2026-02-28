import 'package:flutter/material.dart';

import 'package:fluttag/data/file_system_repository.dart';
import 'package:fluttag/data/id3_repository.dart';
import 'package:fluttag/domain/audio_file.dart';

/// Manages the list of audio files and multi-selection state.
class AudioFileListNotifier extends ChangeNotifier {
  AudioFileListNotifier({
    required FileSystemRepository fileSystemRepository,
    required Id3Repository id3Repository,
  }) : _fileSystemRepository = fileSystemRepository,
       _id3Repository = id3Repository;

  final FileSystemRepository _fileSystemRepository;
  final Id3Repository _id3Repository;

  List<AudioFile> _files = [];
  List<AudioFile> get files => _files;

  final Set<String> _selectedPaths = {};
  Set<String> get selectedPaths => _selectedPaths;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Returns the list of currently selected [AudioFile] objects.
  List<AudioFile> get selectedFiles =>
      _files.where((f) => _selectedPaths.contains(f.path)).toList();

  /// Loads audio files from [folderPath] and reads their tags.
  Future<void> loadFiles(String folderPath) async {
    _isLoading = true;
    _selectedPaths.clear();
    notifyListeners();

    final paths = await _fileSystemRepository.listAudioFiles(folderPath);
    final List<AudioFile> loaded = [];

    for (final path in paths) {
      final audioFile = await _id3Repository.readTags(path);
      loaded.add(audioFile);
    }

    _files = loaded;
    _isLoading = false;
    notifyListeners();
  }

  /// Toggles selection for a single file.
  void toggleSelection(String path) {
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
    } else {
      _selectedPaths.add(path);
    }
    notifyListeners();
  }

  /// Selects all files.
  void selectAll() {
    _selectedPaths.addAll(_files.map((f) => f.path));
    notifyListeners();
  }

  /// Clears all selections.
  void clearSelection() {
    _selectedPaths.clear();
    notifyListeners();
  }

  /// Replaces the cached [AudioFile] entry for a given path after save.
  void updateFile(AudioFile updatedFile) {
    final index = _files.indexWhere((f) => f.path == updatedFile.path);
    if (index != -1) {
      _files[index] = updatedFile;
      notifyListeners();
    }
  }

  /// Reorders a file from [oldIndex] to [newIndex].
  void reorderFile(int oldIndex, int newIndex) {
    // ReorderableListView passes newIndex adjusted for removal.
    var adjustedNew = newIndex;
    if (adjustedNew > oldIndex) {
      adjustedNew -= 1;
    }
    final item = _files.removeAt(oldIndex);
    _files.insert(adjustedNew, item);
    notifyListeners();
  }
}
