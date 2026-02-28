import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:fluttag/models/audio_file.dart';
import 'package:fluttag/repositories/id3_repository.dart';
import 'package:flutter/material.dart';

/// Manages tag editing state, including batch editing for multiple files.
class TagEditorNotifier extends ChangeNotifier {
  TagEditorNotifier({required Id3Repository id3Repository})
    : _id3Repository = id3Repository;

  final Id3Repository _id3Repository;

  List<AudioFile> _editingFiles = [];
  List<AudioFile> get editingFiles => _editingFiles;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _hasChanges = false;
  bool get hasChanges => _hasChanges;

  /// Loads files for editing. Pre-populates common values.
  void loadSelectedFiles(List<AudioFile> files) {
    _editingFiles = files.map((f) => f.copyWith()).toList();
    _hasChanges = false;
    notifyListeners();
  }

  /// Clears the editing state.
  void clear() {
    _editingFiles = [];
    _hasChanges = false;
    notifyListeners();
  }

  /// Returns the common value for a field across all editing files,
  /// or null if values differ.
  String? getCommonValue(String Function(AudioFile) extractor) {
    if (_editingFiles.isEmpty) {
      return null;
    }
    final first = extractor(_editingFiles.first);
    for (final file in _editingFiles.skip(1)) {
      if (extractor(file) != first) {
        return null;
      }
    }
    return first;
  }

  /// Updates a specific field on all editing files.
  void updateTitle(String value) {
    for (final file in _editingFiles) {
      file.title = value;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateArtist(String value) {
    for (final file in _editingFiles) {
      file.artist = value;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateAlbum(String value) {
    for (final file in _editingFiles) {
      file.album = value;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateYear(String value) {
    for (final file in _editingFiles) {
      file.year = value;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateGenre(String value) {
    for (final file in _editingFiles) {
      file.genre = value;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateTrack(String value) {
    for (final file in _editingFiles) {
      file.track = value;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateComment(String value) {
    for (final file in _editingFiles) {
      file.comment = value;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateCoverImage(Uint8List? imageBytes) {
    for (final file in _editingFiles) {
      file.coverImageBytes = imageBytes;
    }
    _hasChanges = true;
    notifyListeners();
  }

  /// Saves all editing files back to disk.
  ///
  /// Returns the list of updated [AudioFile] objects on success.
  Future<List<AudioFile>?> saveAll() async {
    if (_editingFiles.isEmpty) {
      return null;
    }

    _isSaving = true;
    notifyListeners();

    try {
      for (final file in _editingFiles) {
        await _id3Repository.writeTags(file);
      }

      // Re-read tags to confirm the save.
      final refreshed = <AudioFile>[];
      for (final file in _editingFiles) {
        final updated = await _id3Repository.readTags(file.path);
        refreshed.add(updated);
      }

      _editingFiles = refreshed;
      _hasChanges = false;
      _isSaving = false;
      notifyListeners();
      return refreshed;
    } on Exception catch (e) {
      developer.log('Failed to save tags', error: e, name: 'TagEditorNotifier');
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  /// Notifies listeners manually after external modifications to editing files.
  void notifyManually() {
    _hasChanges = true;
    notifyListeners();
  }
}
