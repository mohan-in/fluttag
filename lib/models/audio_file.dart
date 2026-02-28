import 'dart:typed_data';

/// Represents an audio file with its ID3 metadata.
class AudioFile {
  AudioFile({
    required this.path,
    required this.fileName,
    required this.fileSize,
    this.title,
    this.artist,
    this.album,
    this.year,
    this.genre,
    this.track,
    this.comment,
    this.coverImageBytes,
  });

  final String path;
  final String fileName;
  final int fileSize;
  String? title;
  String? artist;
  String? album;
  String? year;
  String? genre;
  String? track;
  String? comment;
  Uint8List? coverImageBytes;

  /// Human-readable file size.
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  AudioFile copyWith({
    String? title,
    String? artist,
    String? album,
    String? year,
    String? genre,
    String? track,
    String? comment,
    Uint8List? coverImageBytes,
  }) {
    return AudioFile(
      path: path,
      fileName: fileName,
      fileSize: fileSize,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      track: track ?? this.track,
      comment: comment ?? this.comment,
      coverImageBytes: coverImageBytes ?? this.coverImageBytes,
    );
  }
}
