import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase(r'C:\Data\Rajesh\Dev\data\MM.DB');
  
  final sql = '''
    SELECT s.ID, s.Artist, s.SongTitle, s.SongPath, s.Extension, m.DriveLetter 
    FROM Songs s
    LEFT JOIN Medias m ON s.IDMedia = m.IDMedia
    WHERE (s.Extension = 'MP4' OR s.Extension = 'mp4' OR s.Extension = 'MKV' OR s.Extension = 'mkv' OR s.Extension = 'AVI' OR s.Extension = 'avi')
    LIMIT 1
  ''';
  
  final results = await db.rawQuery(sql);
  if (results.isEmpty) {
    print("No videos found.");
    return;
  }
  
  final row = results.first;
  var songPath = row['SongPath'] as String? ?? '';
  final driveLetterNum = row['DriveLetter'] as int?;
  
  String fullPath = songPath;
  if (driveLetterNum != null && songPath.startsWith(':\\')) {
    final driveChar = String.fromCharCode(driveLetterNum + 65);
    fullPath = driveChar + songPath;
  }
  
  print("DB SongPath raw: " + songPath);
  print("fullPath generated: " + fullPath);
  print("If we replace '\\\\\\\\' with '/': " + fullPath.replaceAll('\\\\', '/'));
  print("If we replace '\\\\' with '/': " + fullPath.replaceAll('\\', '/'));
  
  File file = File(fullPath);
  print("File exists? " + file.existsSync().toString());
}
