import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/library_song.dart';

class MediaMonkeyServiceImpl {
  Future<void> init() async {}
  
  Future<List<LibrarySong>> searchSongs(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await http.get(Uri.parse('/local-search?q=$encodedQuery'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => LibrarySong.fromMap(item)).toList();
      }
    } catch (e) {
      print('Error searching local media via proxy: $e');
    }
    return [];
  }
}
