import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/library_song.dart';

class MediaMonkeyServiceImpl {
  final String dbPath = r'C:\Data\Rajesh\Dev\data\MM.DB';
  Database? _db;

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      var databaseFactory = databaseFactoryFfi;
      _db = await databaseFactory.openDatabase(dbPath);
    }
  }

  Future<List<LibrarySong>> searchSongs(String query) async {
    if (_db == null) await init();
    if (_db == null) return [];

    // MediaMonkey 4 schema
    // Songs table: ID, Artist, SongTitle, SongPath, IDMedia, Extension
    // Medias table: IDMedia, DriveLetter

    final sql = '''
      SELECT s.ID, s.Artist, s.SongTitle, s.SongPath, s.Extension, m.DriveLetter 
      FROM Songs s
      LEFT JOIN Medias m ON s.IDMedia = m.IDMedia
      WHERE (s.SongTitle LIKE ? OR s.Artist LIKE ?)
        AND (s.Extension = 'MP4' OR s.Extension = 'mp4' OR s.Extension = 'MKV' OR s.Extension = 'mkv' OR s.Extension = 'AVI' OR s.Extension = 'avi')
      LIMIT 30
    ''';

    try {
      final searchPattern = '%$query%';
      final results = await _db!.rawQuery(sql, [searchPattern, searchPattern]);

    return results.map((row) {
      final id = row['ID']?.toString() ?? '';
      final artist = row['Artist'] as String? ?? 'Unknown Artist';
      final title = row['SongTitle'] as String? ?? 'Unknown Title';
      var songPath = row['SongPath'] as String? ?? '';
      final driveLetterNum = row['DriveLetter'] as int?;

      // Resolve actual file path
      // MM4 stores path as ":\path\to\file.mp4" where the colon is a placeholder
      // The actual drive letter is mapped from Medias.DriveLetter (0=A, 1=B, 2=C, etc.)
      String fullPath = songPath;
      if (driveLetterNum != null && songPath.startsWith(':\\')) {
        final driveChar = String.fromCharCode(driveLetterNum + 65); // 0 -> 65 ('A')
        fullPath = '$driveChar$songPath';
      }

      // We will pass the full path as the URL. The host can play it directly from disk.
      // For web clients, the local server will need to intercept this and serve it.
      return LibrarySong(
        id: 'local_$id',
        title: title,
        artist: artist,
        videoId: fullPath,
        source: 'local',
        hasPreview: true,
      );
    }).toList().cast<LibrarySong>();
    } catch (e) {
      print('MediaMonkey search error: $e');
      return [];
    }
  }
}


