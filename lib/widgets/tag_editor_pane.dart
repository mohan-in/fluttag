import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluttag/notifiers/audio_file_list_notifier.dart';
import 'package:fluttag/notifiers/tag_editor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  late AudioFileListNotifier _fileListNotifier;
  late TagEditorNotifier _tagNotifier;

  /// Tracks which file paths are currently loaded in the editor.
  Set<String> _loadedPaths = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newFileListNotifier = context.read<AudioFileListNotifier>();
    final newTagNotifier = context.read<TagEditorNotifier>();

    if (_loadedPaths.isEmpty ||
        _fileListNotifier != newFileListNotifier ||
        _tagNotifier != newTagNotifier) {
      if (_loadedPaths.isNotEmpty) {
        _fileListNotifier.removeListener(_onSelectionChanged);
      }
      _fileListNotifier = newFileListNotifier;
      _tagNotifier = newTagNotifier;
      _fileListNotifier.addListener(_onSelectionChanged);
      _onSelectionChanged();
    }
  }

  @override
  void dispose() {
    _fileListNotifier.removeListener(_onSelectionChanged);
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
    final selectedPaths = _fileListNotifier.selectedPaths;
    if (!_setsEqual(selectedPaths, _loadedPaths)) {
      _loadedPaths = Set<String>.of(selectedPaths);
      final selectedFiles = _fileListNotifier.selectedFiles;
      if (selectedFiles.isEmpty) {
        _tagNotifier.clear();
      } else {
        _tagNotifier.loadSelectedFiles(selectedFiles);
        _populateControllers(_tagNotifier);
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
    final isMultiple = tagNotifier.editingFiles.length > 1;

    // Apply current controller values before saving.
    // For multi-select, only update common fields.
    if (!isMultiple) {
      tagNotifier
        ..updateTitle(_titleController.text)
        ..updateTrack(_trackController.text)
        ..updateComment(_commentController.text);
    }
    tagNotifier
      ..updateArtist(_artistController.text)
      ..updateAlbum(_albumController.text)
      ..updateYear(_yearController.text)
      ..updateGenre(_genreController.text);

    final saved = await tagNotifier.saveAll();

    if (saved != null && mounted) {
      saved.forEach(fileListNotifier.updateFile);

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
              // Per-file fields — disabled when multiple files selected.
              _TagField(
                label: 'Title',
                controller: _titleController,
                enabled: !isMultiple,
                helperText: isMultiple ? 'Per-file field' : null,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.title ?? '') == null,
              ),
              // Common fields — always enabled.
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
              _GenreDropdown(
                controller: _genreController,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.genre ?? '') == null,
              ),
              // Per-file fields — disabled when multiple files selected.
              _TagField(
                label: 'Track',
                controller: _trackController,
                enabled: !isMultiple,
                helperText: isMultiple ? 'Per-file field' : null,
                isMixed:
                    isMultiple &&
                    tagNotifier.getCommonValue((f) => f.track ?? '') == null,
              ),
              _TagField(
                label: 'Comment',
                controller: _commentController,
                maxLines: 3,
                enabled: !isMultiple,
                helperText: isMultiple ? 'Per-file field' : null,
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
          Expanded(
            child: Text(
              isMultiple ? 'Editing $fileCount files' : 'Tag Editor',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
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
    this.enabled = true,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool isMixed;
  final bool enabled;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: isMixed ? '(Multiple values)' : null,
          helperText: helperText,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

/// Genre field with autocomplete dropdown of standard ID3 genres.
class _GenreDropdown extends StatelessWidget {
  const _GenreDropdown({required this.controller, this.isMixed = false});

  final TextEditingController controller;
  final bool isMixed;

  static const List<String> _genres = [
    'Acoustic',
    'Alternative',
    'Ambient',
    'Audiobook',
    'Blues',
    'Classical',
    'Comedy',
    'Country',
    'Dance',
    'Disco',
    'Drama',
    'Drum & Bass',
    'Electronic',
    'Folk',
    'Funk',
    'Gospel',
    'Grunge',
    'Hip-Hop',
    'House',
    'Indie',
    'Jazz',
    'K-Pop',
    'Latin',
    'Lo-Fi',
    'Metal',
    'New Age',
    'Opera',
    'Other',
    'Podcast',
    'Pop',
    'Punk',
    'R&B',
    'Rap',
    'Reggae',
    'Rock',
    'Soul',
    'Soundtrack',
    'Techno',
    'Trance',
    'World',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Autocomplete<String>(
            initialValue: controller.value,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _genres;
              }
              final query = textEditingValue.text.toLowerCase();
              return _genres.where((g) => g.toLowerCase().contains(query));
            },
            onSelected: (value) {
              controller.text = value;
            },
            fieldViewBuilder:
                (context, fieldController, focusNode, onFieldSubmitted) {
                  // Sync the external controller when the field changes.
                  fieldController.addListener(() {
                    if (controller.text != fieldController.text) {
                      controller.text = fieldController.text;
                    }
                  });

                  return TextField(
                    controller: fieldController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Genre',
                      hintText: isMixed ? '(Multiple values)' : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: constraints.maxWidth,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
