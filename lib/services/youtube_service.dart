import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/library_song.dart';

class YouTubeService {
  final YoutubeExplode yt = YoutubeExplode();

  Future<List<LibrarySong>> searchSongs(String query) async {
    if (kIsWeb) {
      try {
        final encodedQuery = Uri.encodeQueryComponent(query);
        final response = await http.get(Uri.parse('/search?q=$encodedQuery'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((item) => LibrarySong.fromMap(item)).toList();
        }
      } catch (e) {
        print('Error searching via proxy: $e');
      }
      return [];
    }

    // Native implementation
    final searchResults = await yt.search.search('$query karaoke');
    
    return searchResults.map((video) {
      return LibrarySong(
        id: video.id.value,
        title: video.title,
        artist: video.author, // YouTube Channel Name
        videoId: video.id.value,
        rating: 5,
        source: 'youtube',
        hasPreview: true,
      );
    }).toList();
  }

  Future<String?> getVideoStreamUrl(String videoId) async {
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      print('Error getting video stream: $e');
      return null;
    }
  }

  void dispose() {
    yt.close();
  }
}

final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService();
  ref.onDispose(() => service.dispose());
  return service;
});
