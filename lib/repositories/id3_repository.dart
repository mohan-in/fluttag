import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:fluttag/models/audio_file.dart';

/// Repository for reading and writing audio tags using audiotags.
///
/// Supports MP3, M4A, FLAC, OGG, Opus, WAV, and more.
class Id3Repository {
  /// Reads audio tags from the file at [filePath].
  Future<AudioFile> readTags(String filePath) async {
    final file = File(filePath);
    final stat = file.statSync();
    final fileName = filePath.split(Platform.pathSeparator).last;

    String? title;
    String? artist;
    String? album;
    String? year;
    String? genre;
    String? track;
    String? comment;
    Uint8List? coverImageBytes;

    try {
      final tag = await AudioTags.read(filePath);

      if (tag != null) {
        title = tag.title;
        artist = tag.trackArtist;
        album = tag.album;
        year = tag.year?.toString();
        genre = tag.genre;
        track = tag.trackNumber?.toString();
        // audiotags doesn't expose a comment field directly.
        comment = null;

        // Extract cover image from first picture.
        if (tag.pictures.isNotEmpty) {
          coverImageBytes = tag.pictures.first.bytes;
        }

        developer.log(
          'Read tags for $fileName: title=$title, artist=$artist, '
          'album=$album, year=$year, genre=$genre, track=$track',
          name: 'Id3Repository',
        );
      } else {
        developer.log('No tags found for $fileName', name: 'Id3Repository');
      }
    } on Exception catch (e) {
      developer.log(
        'Failed to read tags from $filePath',
        error: e,
        name: 'Id3Repository',
      );
    }

    return AudioFile(
      path: filePath,
      fileName: fileName,
      fileSize: stat.size,
      title: title,
      artist: artist,
      album: album,
      year: year,
      genre: genre,
      track: track,
      comment: comment,
      coverImageBytes: coverImageBytes,
    );
  }

  /// Writes audio tags from [audioFile] back to disk.
  ///
  /// Supports all fields: title, artist, album, year, genre, track, and cover.
  Future<void> writeTags(AudioFile audioFile) async {
    developer.log(
      'Writing tags to ${audioFile.fileName}: '
      'title=${audioFile.title}, artist=${audioFile.artist}, '
      'album=${audioFile.album}, year=${audioFile.year}, '
      'genre=${audioFile.genre}, track=${audioFile.track}',
      name: 'Id3Repository',
    );

    final pictures = audioFile.coverImageBytes != null
        ? <Picture>[
            Picture(
              bytes: audioFile.coverImageBytes!,
              pictureType: PictureType.other,
            ),
          ]
        : <Picture>[];

    final tag = Tag(
      title: audioFile.title,
      trackArtist: audioFile.artist,
      album: audioFile.album,
      year: audioFile.year != null ? int.tryParse(audioFile.year!) : null,
      genre: audioFile.genre,
      trackNumber: audioFile.track != null
          ? int.tryParse(audioFile.track!)
          : null,
      pictures: pictures,
    );

    await AudioTags.write(audioFile.path, tag);

    developer.log(
      'Successfully wrote tags to ${audioFile.fileName}',
      name: 'Id3Repository',
    );
  }
}
