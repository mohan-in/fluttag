import 'package:flutter/material.dart';

/// Available columns for the audio file list.
enum FileColumn {
  title('Title'),
  artist('Artist'),
  album('Album'),
  year('Year'),
  genre('Genre'),
  track('Track'),
  comment('Comment'),
  fileSize('File Size')
  ;

  const FileColumn(this.label);
  final String label;
}

/// Manages which columns are visible and their widths.
class ColumnSettingsNotifier extends ChangeNotifier {
  final Map<FileColumn, bool> _visibility = {
    FileColumn.title: true,
    FileColumn.artist: true,
    FileColumn.album: true,
    FileColumn.year: false,
    FileColumn.genre: true,
    FileColumn.track: true,
    FileColumn.comment: false,
    FileColumn.fileSize: false,
  };

  /// Per-column widths set by user drag.
  final Map<FileColumn, double> _widths = {};

  /// Default widths per column type.
  static const double _defaultNarrowWidth = 80;
  static const double _defaultWideWidth = 160;
  static const double _minColumnWidth = 50;
  static const double _maxColumnWidth = 500;

  static const double checkboxColumnWidth = 48;

  double _fileNameWidth = 220;
  double get fileNameWidth => _fileNameWidth;

  Map<FileColumn, bool> get visibility => Map.unmodifiable(_visibility);

  /// Returns only the visible columns in enum order.
  List<FileColumn> get visibleColumns =>
      FileColumn.values.where((c) => _visibility[c] ?? false).toList();

  /// Returns the width for a given column.
  double columnWidth(FileColumn column) {
    if (_widths.containsKey(column)) {
      return _widths[column]!;
    }
    switch (column) {
      case FileColumn.year:
      case FileColumn.track:
        return _defaultNarrowWidth;
      case FileColumn.fileSize:
        return 100;
      case FileColumn.title:
      case FileColumn.artist:
      case FileColumn.album:
      case FileColumn.genre:
      case FileColumn.comment:
        return _defaultWideWidth;
    }
  }

  /// Resizes a column by [delta] pixels.
  void resizeColumn(FileColumn column, double delta) {
    final current = columnWidth(column);
    _widths[column] = (current + delta).clamp(_minColumnWidth, _maxColumnWidth);
    notifyListeners();
  }

  /// Resizes the file name column by [delta] pixels.
  void resizeFileNameColumn(double delta) {
    _fileNameWidth = (_fileNameWidth + delta).clamp(
      _minColumnWidth,
      _maxColumnWidth,
    );
    notifyListeners();
  }

  /// Toggles visibility of a column.
  void toggleColumn(FileColumn column) {
    _visibility[column] = !(_visibility[column] ?? false);
    notifyListeners();
  }
}
