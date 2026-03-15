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

  final Map<String, AudioFile> _draftFiles = {};

  bool isModified(String path) => _draftFiles.containsKey(path);
  AudioFile? getDraft(String path) => _draftFiles[path];
  int get modifiedFilesCount => _draftFiles.length;

  /// Loads files for editing. Preserves unsaved changes
  /// for files that are still selected.
  void loadSelectedFiles(List<AudioFile> files) {
    final oldMap = {for (final f in _editingFiles) f.path: f};

    _editingFiles = files.map((f) {
      // Prefer current editing copy, then draft, then fresh copy.
      if (oldMap.containsKey(f.path)) {
        return oldMap[f.path]!;
      }
      if (_draftFiles.containsKey(f.path)) {
        return _draftFiles[f.path]!;
      }
      return f.copyWith();
    }).toList();

    _hasChanges = _draftFiles.isNotEmpty;
    notifyListeners();
  }

  /// Clears the editing state.
  void clear() {
    _editingFiles = [];
    _hasChanges = _draftFiles.isNotEmpty;
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
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateArtist(String value) {
    for (final file in _editingFiles) {
      file.artist = value;
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateAlbum(String value) {
    for (final file in _editingFiles) {
      file.album = value;
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateYear(String value) {
    for (final file in _editingFiles) {
      file.year = value;
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateGenre(String value) {
    for (final file in _editingFiles) {
      file.genre = value;
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateTrack(String value) {
    for (final file in _editingFiles) {
      file.track = value;
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateComment(String value) {
    for (final file in _editingFiles) {
      file.comment = value;
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  void updateCoverImage(Uint8List? imageBytes) {
    for (final file in _editingFiles) {
      file.coverImageBytes = imageBytes;
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  /// Automatically assigns track numbers 1 through N to the
  /// currently selected files.
  void autoNumberTracks() {
    for (var i = 0; i < _editingFiles.length; i++) {
      _editingFiles[i].track = (i + 1).toString();
      _draftFiles[_editingFiles[i].path] = _editingFiles[i];
    }
    _hasChanges = true;
    notifyListeners();
  }

  String? _duplicateTitleError;
  String? get duplicateTitleError => _duplicateTitleError;

  /// Saves all editing files back to disk.
  ///
  /// Returns the list of updated [AudioFile] objects on success.
  /// Returns `null` if there are duplicate titles or no drafts.
  Future<List<AudioFile>?> saveAll() async {
    if (_draftFiles.isEmpty) {
      return null;
    }

    _duplicateTitleError = null;
    _isSaving = true;
    notifyListeners();

    try {
      // Resolve %field% templates before writing.
      final resolved = _draftFiles.values.map(_resolveTemplates).toList();

      // Validate no duplicate titles.
      final titles = <String, String>{};
      for (final file in resolved) {
        final title = file.title ?? '';
        if (title.isNotEmpty && titles.containsKey(title)) {
          _duplicateTitleError =
              'Duplicate title "$title" found in '
              '"${titles[title]}" and "${file.fileName}"';
          _isSaving = false;
          notifyListeners();
          return null;
        }
        if (title.isNotEmpty) {
          titles[title] = file.fileName;
        }
      }

      for (final file in resolved) {
        await _id3Repository.writeTags(file);
      }

      // Re-read tags to confirm the save.
      final refreshed = <AudioFile>[];
      for (final file in resolved) {
        final updated = await _id3Repository.readTags(file.path);
        refreshed.add(updated);
      }

      for (var i = 0; i < _editingFiles.length; i++) {
        final path = _editingFiles[i].path;
        final idx = refreshed.indexWhere((f) => f.path == path);
        if (idx != -1) {
          _editingFiles[i] = refreshed[idx];
        }
      }

      _draftFiles.clear();
      _hasChanges = false;
      _isSaving = false;
      notifyListeners();
      return refreshed;
    } on Exception catch (e) {
      developer.log(
        'Failed to save tags',
        error: e,
        name: 'TagEditorNotifier',
      );
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  /// Notifies listeners manually after external
  /// modifications to editing files.
  void notifyManually() {
    for (final file in _editingFiles) {
      _draftFiles[file.path] = file;
    }
    _hasChanges = true;
    notifyListeners();
  }

  /// Resolves `%field%` template tokens in all tag fields
  /// of [file] using the file's own pre-resolution values.
  AudioFile _resolveTemplates(AudioFile file) {
    final baseName = file.fileName.contains('.')
        ? file.fileName.substring(
            0,
            file.fileName.lastIndexOf('.'),
          )
        : file.fileName;

    // Snapshot original values before resolution.
    final tokens = <String, String>{
      'title': file.title ?? '',
      'artist': file.artist ?? '',
      'album': file.album ?? '',
      'year': file.year ?? '',
      'genre': file.genre ?? '',
      'track': file.track ?? '',
      'comment': file.comment ?? '',
      'filename': baseName,
    };

    String resolve(String? value) {
      if (value == null || !value.contains('%')) {
        return value ?? '';
      }
      var result = value;
      for (final entry in tokens.entries) {
        result = result.replaceAll(
          '%${entry.key}%',
          entry.value,
        );
      }
      return result;
    }

    return file.copyWith(
      title: resolve(file.title),
      artist: resolve(file.artist),
      album: resolve(file.album),
      year: resolve(file.year),
      genre: resolve(file.genre),
      track: resolve(file.track),
      comment: resolve(file.comment),
    );
  }
}
