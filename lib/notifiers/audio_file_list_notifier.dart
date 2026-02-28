import 'package:fluttag/models/audio_file.dart';
import 'package:fluttag/notifiers/column_settings_notifier.dart';
import 'package:fluttag/repositories/file_system_repository.dart';
import 'package:fluttag/repositories/id3_repository.dart';
import 'package:flutter/material.dart';

/// Which column the list is sorted by.
/// [fileName] is a special case for the fixed file name column.
enum SortColumn { fileName, fileColumn }

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

  /// Current sort state.
  FileColumn? _sortFileColumn;
  FileColumn? get sortFileColumn => _sortFileColumn;

  bool _sortByFileName = false;
  bool get sortByFileName => _sortByFileName;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  /// Returns the list of currently selected [AudioFile] objects.
  List<AudioFile> get selectedFiles =>
      _files.where((f) => _selectedPaths.contains(f.path)).toList();

  /// Loads audio files from [folderPath] and reads their tags.
  Future<void> loadFiles(String folderPath) async {
    _isLoading = true;
    _selectedPaths.clear();
    notifyListeners();

    final paths = await _fileSystemRepository.listAudioFiles(folderPath);
    final loaded = <AudioFile>[];

    for (final path in paths) {
      final audioFile = await _id3Repository.readTags(path);
      loaded.add(audioFile);
    }

    _files = loaded;
    _isLoading = false;

    // Re-apply current sort if one is active.
    if (_sortByFileName || _sortFileColumn != null) {
      _applySort();
    }

    notifyListeners();
  }

  /// Sorts by the file name column. Toggles direction if already active.
  void sortByFileNameColumn() {
    if (_sortByFileName) {
      _sortAscending = !_sortAscending;
    } else {
      _sortByFileName = true;
      _sortFileColumn = null;
      _sortAscending = true;
    }
    _applySort();
    notifyListeners();
  }

  /// Sorts by a [FileColumn]. Toggles direction if already active.
  void sortByColumn(FileColumn column) {
    if (_sortFileColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortFileColumn = column;
      _sortByFileName = false;
      _sortAscending = true;
    }
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    final ascending = _sortAscending;

    if (_sortByFileName) {
      _files.sort((a, b) {
        final cmp = a.fileName.toLowerCase().compareTo(
          b.fileName.toLowerCase(),
        );
        return ascending ? cmp : -cmp;
      });
      return;
    }

    final column = _sortFileColumn;
    if (column == null) {
      return;
    }

    _files.sort((a, b) {
      int cmp;
      // Use numeric comparison for numeric columns.
      if (column == FileColumn.track ||
          column == FileColumn.year ||
          column == FileColumn.fileSize) {
        final na = _getNumericValue(a, column);
        final nb = _getNumericValue(b, column);
        cmp = na.compareTo(nb);
      } else {
        final va = _getValue(a, column).toLowerCase();
        final vb = _getValue(b, column).toLowerCase();
        cmp = va.compareTo(vb);
      }
      return ascending ? cmp : -cmp;
    });
  }

  int _getNumericValue(AudioFile file, FileColumn column) {
    switch (column) {
      case FileColumn.track:
        return int.tryParse(file.track ?? '') ?? 0;
      case FileColumn.year:
        return int.tryParse(file.year ?? '') ?? 0;
      case FileColumn.fileSize:
        return file.fileSize;
      case FileColumn.title:
      case FileColumn.artist:
      case FileColumn.album:
      case FileColumn.genre:
      case FileColumn.comment:
        return 0;
    }
  }

  String _getValue(AudioFile file, FileColumn column) {
    switch (column) {
      case FileColumn.title:
        return file.title ?? '';
      case FileColumn.artist:
        return file.artist ?? '';
      case FileColumn.album:
        return file.album ?? '';
      case FileColumn.year:
        return file.year ?? '';
      case FileColumn.genre:
        return file.genre ?? '';
      case FileColumn.track:
        return file.track ?? '';
      case FileColumn.comment:
        return file.comment ?? '';
      case FileColumn.fileSize:
        return file.fileSize.toString().padLeft(12, '0');
    }
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
    var adjustedNew = newIndex;
    if (adjustedNew > oldIndex) {
      adjustedNew -= 1;
    }
    final item = _files.removeAt(oldIndex);
    _files.insert(adjustedNew, item);
    notifyListeners();
  }
}
