import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluttag/domain/audio_file.dart';
import 'package:fluttag/notifiers/audio_file_list_notifier.dart';
import 'package:fluttag/notifiers/column_settings_notifier.dart';

/// Middle pane: displays the list of audio files with resizable columns.
class AudioFileListPane extends StatefulWidget {
  const AudioFileListPane({super.key});

  @override
  State<AudioFileListPane> createState() => _AudioFileListPaneState();
}

class _AudioFileListPaneState extends State<AudioFileListPane> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileNotifier = context.watch<AudioFileListNotifier>();
    final columnNotifier = context.watch<ColumnSettingsNotifier>();
    final theme = Theme.of(context);

    if (fileNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fileNotifier.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audio_file, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No audio files in this folder',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final visibleColumns = columnNotifier.visibleColumns;
    final allSelected =
        fileNotifier.selectedPaths.length == fileNotifier.files.length &&
        fileNotifier.files.isNotEmpty;

    // Calculate total row width so header and data rows match.
    final totalRowWidth = _calcRowWidth(columnNotifier, visibleColumns);

    return Column(
      children: [
        _FileListHeader(
          fileCount: fileNotifier.files.length,
          selectedCount: fileNotifier.selectedPaths.length,
        ),
        const Divider(height: 1),
        // Scrollable header + data, sharing horizontal scroll.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SizedBox(
                      width: totalRowWidth < constraints.maxWidth
                          ? constraints.maxWidth
                          : totalRowWidth,
                      child: Column(
                        children: [
                          // Header row.
                          _ResizableHeaderRow(
                            allSelected: allSelected,
                            visibleColumns: visibleColumns,
                            columnNotifier: columnNotifier,
                            onSelectAll: () {
                              if (allSelected) {
                                fileNotifier.clearSelection();
                              } else {
                                fileNotifier.selectAll();
                              }
                            },
                          ),
                          const Divider(height: 1),
                          // Data rows (reorderable).
                          Expanded(
                            child: ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              onReorder: fileNotifier.reorderFile,
                              itemCount: fileNotifier.files.length,
                              itemExtent: 36,
                              itemBuilder: (context, index) {
                                final file = fileNotifier.files[index];
                                final isSelected = fileNotifier.selectedPaths
                                    .contains(file.path);
                                return _FileRow(
                                  key: ValueKey(file.path),
                                  index: index,
                                  file: file,
                                  isSelected: isSelected,
                                  visibleColumns: visibleColumns,
                                  columnNotifier: columnNotifier,
                                  onToggle: () =>
                                      fileNotifier.toggleSelection(file.path),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Calculates the total width of a row given current column widths.
  double _calcRowWidth(
    ColumnSettingsNotifier columnNotifier,
    List<FileColumn> visibleColumns,
  ) {
    double width = 24; // Drag handle.
    width += ColumnSettingsNotifier.checkboxColumnWidth; // Checkbox.
    width += 1; // VerticalDivider.
    width += columnNotifier.fileNameWidth; // File name.
    width += 8; // Divider spacer.
    for (final col in visibleColumns) {
      width += columnNotifier.columnWidth(col);
      width += 8; // Divider spacer.
    }
    return width;
  }
}

/// A single resizable column divider handle.
class _ColumnDivider extends StatelessWidget {
  const _ColumnDivider({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: SizedBox(
          width: 8,
          child: Center(
            child: Container(width: 1, color: theme.colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

/// Header row with column labels and draggable dividers between them.
class _ResizableHeaderRow extends StatelessWidget {
  const _ResizableHeaderRow({
    required this.allSelected,
    required this.visibleColumns,
    required this.columnNotifier,
    required this.onSelectAll,
  });

  final bool allSelected;
  final List<FileColumn> visibleColumns;
  final ColumnSettingsNotifier columnNotifier;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          // Spacer matching drag handle width in data rows.
          const SizedBox(width: 24),
          // Checkbox column (fixed width).
          SizedBox(
            width: ColumnSettingsNotifier.checkboxColumnWidth,
            child: Center(
              child: Checkbox(
                value: allSelected,
                onChanged: (_) => onSelectAll(),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // File name column + divider.
          SizedBox(
            width: columnNotifier.fileNameWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('File Name', style: headerStyle),
              ),
            ),
          ),
          _ColumnDivider(
            onDrag: (delta) => columnNotifier.resizeFileNameColumn(delta),
          ),
          // Dynamic visible columns.
          for (final column in visibleColumns) ...[
            SizedBox(
              width: columnNotifier.columnWidth(column),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(column.label, style: headerStyle),
                ),
              ),
            ),
            _ColumnDivider(
              onDrag: (delta) => columnNotifier.resizeColumn(column, delta),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single file data row matching the header widths.
class _FileRow extends StatelessWidget {
  const _FileRow({
    super.key,
    required this.index,
    required this.file,
    required this.isSelected,
    required this.visibleColumns,
    required this.columnNotifier,
    required this.onToggle,
  });

  final int index;
  final AudioFile file;
  final bool isSelected;
  final List<FileColumn> visibleColumns;
  final ColumnSettingsNotifier columnNotifier;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: ClipRect(
          child: Row(
            children: [
              // Drag handle.
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
              // Checkbox.
              SizedBox(
                width: ColumnSettingsNotifier.checkboxColumnWidth,
                child: Center(
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              // File name.
              SizedBox(
                width: columnNotifier.fileNameWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    file.fileName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              // Divider spacer to match header.
              const SizedBox(width: 8),
              // Dynamic columns.
              for (final column in visibleColumns) ...[
                SizedBox(
                  width: columnNotifier.columnWidth(column),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _getCellValue(column),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Divider spacer.
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getCellValue(FileColumn column) {
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
        return file.formattedSize;
    }
  }
}

class _FileListHeader extends StatelessWidget {
  const _FileListHeader({required this.fileCount, required this.selectedCount});

  final int fileCount;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.queue_music, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$fileCount files',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (selectedCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$selectedCount selected',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
