import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:fluttag/domain/audio_file.dart';
import 'package:id3_codec/id3_codec.dart';

/// Repository for reading and writing ID3 tags using id3_codec.
class Id3Repository {
  /// Reads ID3 tags from the audio file at [filePath].
  Future<AudioFile> readTags(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final stat = await file.stat();
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
      final decoder = ID3Decoder(bytes);
      final metadataList = decoder.decodeSync();

      // Build a frame-ID-indexed map from all metadata blocks.
      // ID3v1 blocks have flat keys: Title, Artist, Album, Year, etc.
      // ID3v2 blocks have nested: Frames → list of maps with
      //   'Frame ID' and 'Content' → {'Information': '...'}.
      final Map<String, dynamic> v1Tags = {};
      final Map<String, Map<String, dynamic>> v2Frames = {};

      for (final metadata in metadataList) {
        final tagMap = metadata.toTagMap();

        // ID3v1: flat keys like Title, Artist, Album, Year, Comment, Genre.
        if (tagMap.containsKey('Title')) {
          v1Tags.addAll(tagMap);
        }

        // ID3v2: Frames list.
        final frames = tagMap['Frames'];
        if (frames is List) {
          for (final frame in frames) {
            if (frame is Map) {
              final frameId = frame['Frame ID'];
              if (frameId is String) {
                v2Frames[frameId] = Map<String, dynamic>.from(frame);
              }
            }
          }
        }
      }

      developer.log(
        'v1 keys: ${v1Tags.keys.toList()}, '
        'v2 frame IDs: ${v2Frames.keys.toList()}',
        name: 'Id3Repository',
      );

      // Prefer ID3v2 data, fall back to ID3v1.
      title = _v2Info(v2Frames, 'TIT2') ?? _v1String(v1Tags, 'Title');
      artist = _v2Info(v2Frames, 'TPE1') ?? _v1String(v1Tags, 'Artist');
      album = _v2Info(v2Frames, 'TALB') ?? _v1String(v1Tags, 'Album');
      year =
          _v2Info(v2Frames, 'TDRC') ??
          _v2Info(v2Frames, 'TYER') ??
          _v1String(v1Tags, 'Year');
      genre = _v2Info(v2Frames, 'TCON') ?? _v1String(v1Tags, 'Genre');
      track = _v2Info(v2Frames, 'TRCK');
      comment = _v2Info(v2Frames, 'COMM') ?? _v1String(v1Tags, 'Comment');

      // Extract cover image from APIC frame.
      coverImageBytes = _extractApic(v2Frames);

      developer.log(
        'Parsed: title=$title, artist=$artist, album=$album',
        name: 'Id3Repository',
      );
    } on Exception catch (e) {
      developer.log(
        'Failed to read ID3 tags from $filePath',
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

  /// Writes ID3 tags from [audioFile] back to disk.
  ///
  /// Uses ID3v2.4 encoding via [MetadataV2p4Body].
  Future<void> writeTags(AudioFile audioFile) async {
    final file = File(audioFile.path);
    final bytes = await file.readAsBytes();

    developer.log(
      'Writing tags to ${audioFile.fileName}: '
      'title=${audioFile.title}, artist=${audioFile.artist}, '
      'album=${audioFile.album}',
      name: 'Id3Repository',
    );

    final encoder = ID3Encoder(bytes);
    final resultBytes = encoder.encodeSync(
      MetadataV2p4Body(
        title: audioFile.title ?? '',
        artist: audioFile.artist ?? '',
        album: audioFile.album ?? '',
        imageBytes: audioFile.coverImageBytes,
      ),
    );

    await file.writeAsBytes(resultBytes);

    developer.log(
      'Wrote ${resultBytes.length} bytes to ${audioFile.fileName}',
      name: 'Id3Repository',
    );
  }

  /// Extracts the 'Information' string from an ID3v2 frame's Content map.
  ///
  /// Frame structure: {'Frame ID': 'TIT2', 'Content': {'Information': '...'}}
  String? _v2Info(Map<String, Map<String, dynamic>> frames, String frameId) {
    final frame = frames[frameId];
    if (frame == null) {
      return null;
    }
    final content = frame['Content'];
    if (content is Map) {
      final info = content['Information'];
      if (info is String && info.isNotEmpty) {
        return info;
      }
    }
    // Fallback: try content.toString().
    if (content != null) {
      final str = content.toString();
      if (str.isNotEmpty && str != '{}') {
        return str;
      }
    }
    return null;
  }

  /// Extracts a string value from ID3v1 flat tag map.
  String? _v1String(Map<String, dynamic> v1Tags, String key) {
    final value = v1Tags[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  /// Extracts cover image bytes from the APIC frame, if present.
  Uint8List? _extractApic(Map<String, Map<String, dynamic>> frames) {
    final frame = frames['APIC'];
    if (frame == null) {
      return null;
    }

    final content = frame['Content'];
    if (content is Map) {
      // Check for 'image' key in the Content map.
      final imageData = content['image'];
      if (imageData is Uint8List) {
        return imageData;
      }
      if (imageData is List<int>) {
        return Uint8List.fromList(imageData);
      }
      // Check for 'Picture data' key.
      final pictureData = content['Picture data'];
      if (pictureData is Uint8List) {
        return pictureData;
      }
      if (pictureData is List<int>) {
        return Uint8List.fromList(pictureData);
      }
    }

    return null;
  }
}
