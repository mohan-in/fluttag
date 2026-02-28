import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluttag/notifiers/audio_file_list_notifier.dart';
import 'package:fluttag/notifiers/tag_editor_notifier.dart';

/// Right pane: displays and edits ID3 tag fields for selected files.
class TagEditorPane extends StatefulWidget {
  const TagEditorPane({super.key});

  @override
  State<TagEditorPane> createState() => _TagEditorPaneState();
}

class _TagEditorPaneState extends State<TagEditorPane> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _yearController = TextEditingController();
  final _genreController = TextEditingController();
  final _trackController = TextEditingController();
  final _commentController = TextEditingController();

  AudioFileListNotifier? _fileListNotifier;
  TagEditorNotifier? _tagNotifier;

  /// Tracks which file paths are currently loaded in the editor.
  Set<String> _loadedPaths = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newFileListNotifier = context.read<AudioFileListNotifier>();
    final newTagNotifier = context.read<TagEditorNotifier>();

    if (_fileListNotifier != newFileListNotifier) {
      _fileListNotifier?.removeListener(_onSelectionChanged);
      _fileListNotifier = newFileListNotifier;
      _tagNotifier = newTagNotifier;
      _fileListNotifier!.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    _fileListNotifier?.removeListener(_onSelectionChanged);
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _trackController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// Runs outside of build when AudioFileListNotifier changes.
  void _onSelectionChanged() {
    final selectedPaths = _fileListNotifier!.selectedPaths;
    developer.log(
      'onSelectionChanged: selectedPaths=$selectedPaths, '
      'loadedPaths=$_loadedPaths',
      name: 'TagEditorPane',
    );
    if (!_setsEqual(selectedPaths, _loadedPaths)) {
      _loadedPaths = Set<String>.of(selectedPaths);
      final selectedFiles = _fileListNotifier!.selectedFiles;
      developer.log(
        'Selection changed! selectedFiles.length=${selectedFiles.length}',
        name: 'TagEditorPane',
      );
      if (selectedFiles.isEmpty) {
        _tagNotifier!.clear();
      } else {
        _tagNotifier!.loadSelectedFiles(selectedFiles);
        developer.log(
          'After loadSelectedFiles: editingFiles.length='
          '${_tagNotifier!.editingFiles.length}, '
          'title=${_tagNotifier!.editingFiles.first.title}',
          name: 'TagEditorPane',
        );
        _populateControllers(_tagNotifier!);
        developer.log(
          'After populateControllers: titleCtrl=${_titleController.text}',
          name: 'TagEditorPane',
        );
      }
    }
  }

  void _populateControllers(TagEditorNotifier notifier) {
    _titleController.text = notifier.getCommonValue((f) => f.title ?? '') ?? '';
    _artistController.text =
        notifier.getCommonValue((f) => f.artist ?? '') ?? '';
    _albumController.text = notifier.getCommonValue((f) => f.album ?? '') ?? '';
    _yearController.text = notifier.getCommonValue((f) => f.year ?? '') ?? '';
    _genreController.text = notifier.getCommonValue((f) => f.genre ?? '') ?? '';
    _trackController.text = notifier.getCommonValue((f) => f.track ?? '') ?? '';
    _commentController.text =
        notifier.getCommonValue((f) => f.comment ?? '') ?? '';
  }

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Select Cover Image',
    );

    if (result != null && result.files.single.path != null) {
      final imageFile = File(result.files.single.path!);
      final bytes = await imageFile.readAsBytes();
      if (mounted) {
        context.read<TagEditorNotifier>().updateCoverImage(bytes);
      }
    }
  }

  Future<void> _handleSave() async {
    final tagNotifier = context.read<TagEditorNotifier>();
    final fileListNotifier = context.read<AudioFileListNotifier>();

    // Apply current controller values before saving.
    tagNotifier
      ..updateTitle(_titleController.text)
      ..updateArtist(_artistController.text)
      ..updateAlbum(_albumController.text)
      ..updateYear(_yearController.text)
      ..updateGenre(_genreController.text)
      ..updateTrack(_trackController.text)
      ..updateComment(_commentController.text);

    final saved = await tagNotifier.saveAll();

    if (saved != null && mounted) {
      for (final updated in saved) {
        fileListNotifier.updateFile(updated);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${saved.length} file(s)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagNotifier = context.watch<TagEditorNotifier>();
    final theme = Theme.of(context);

    developer.log(
      'build: editingFiles.length=${tagNotifier.editingFiles.length}',
      name: 'TagEditorPane',
    );

    if (tagNotifier.editingFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Select files to edit tags',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final coverImage = tagNotifier.editingFiles.first.coverImageBytes;
    final isMultiple = tagNotifier.editingFiles.length > 1;

    return Column(
      children: [
        _TagEditorHeader(
          fileCount: tagNotifier.editingFiles.length,
          isMultiple: isMultiple,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cover Image.
              Center(
                child: GestureDetector(
                  onTap: _pickCoverImage,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: coverImage != null
                        ? Image.memory(coverImage, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.album,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No cover art',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickCoverImage,
                  icon: const Icon(Icons.image, size: 16),
                  label: const Text('Change Cover'),
                ),
              ),
              const SizedBox(height: 16),
              _TagField(
                label: 'Title',
                controller: _titleController,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.title ?? '') == null,
              ),
              _TagField(
                label: 'Artist',
                controller: _artistController,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.artist ?? '') == null,
              ),
              _TagField(
                label: 'Album',
                controller: _albumController,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.album ?? '') == null,
              ),
              _TagField(
                label: 'Year',
                controller: _yearController,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.year ?? '') == null,
              ),
              _TagField(
                label: 'Genre',
                controller: _genreController,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.genre ?? '') == null,
              ),
              _TagField(
                label: 'Track',
                controller: _trackController,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.track ?? '') == null,
              ),
              _TagField(
                label: 'Comment',
                controller: _commentController,
                maxLines: 3,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.comment ?? '') == null,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: tagNotifier.isSaving ? null : _handleSave,
                icon: tagNotifier.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  tagNotifier.isSaving
                      ? 'Saving...'
                      : 'Save ${tagNotifier.editingFiles.length} file(s)',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagEditorHeader extends StatelessWidget {
  const _TagEditorHeader({required this.fileCount, required this.isMultiple});

  final int fileCount;
  final bool isMultiple;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            isMultiple ? 'Editing $fileCount files' : 'Tag Editor',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagField extends StatelessWidget {
  const _TagField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.isMixed = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool isMixed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: isMixed ? '(Multiple values)' : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
