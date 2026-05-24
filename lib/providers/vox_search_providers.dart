import 'package:vox_player_core/vox_player_core.dart';
import '../services/youtube_service.dart';
import '../services/smule_service.dart';
import '../models/library_song.dart';

extension LibrarySongExtension on LibrarySong {
  VoxSearchResult toVoxSearchResult(String providerId) {
    return VoxSearchResult(
      id: id,
      title: title,
      artist: artist,
      sourceType: providerId,
      url: videoId, // Use videoId as the URL identifier
      metadata: {
        'rating': rating,
        'hasPreview': hasPreview,
      },
    );
  }
}

class YoutubeVoxSearchProvider extends VoxSearchProvider {
  final YouTubeService youtubeService;

  YoutubeVoxSearchProvider(this.youtubeService);

  @override
  String get providerId => 'youtube';

  @override
  String get displayName => 'YouTube';

  @override
  Future<List<VoxSearchResult>> search(String query, {Map<String, dynamic>? filters}) async {
    if (query.isEmpty) return [];
    try {
      final results = await youtubeService.searchSongs(query);
      return results.map((e) => e.toVoxSearchResult(providerId)).toList();
    } catch (e) {
      print('YouTube search error: $e');
      return [];
    }
  }

  @override
  Future<String?> resolveStreamUrl(VoxSearchResult result) async {
    try {
      return await youtubeService.getVideoStreamUrl(result.url ?? '');
    } catch (e) {
      print('YouTube resolve error: $e');
      return null;
    }
  }
}

class SmuleVoxSearchProvider extends VoxSearchProvider {
  final SmuleService smuleService;

  SmuleVoxSearchProvider(this.smuleService);

  @override
  String get providerId => 'smule';

  @override
  String get displayName => 'Smule';

  @override
  Future<List<VoxSearchResult>> search(String query, {Map<String, dynamic>? filters}) async {
    if (query.isEmpty) return [];
    try {
      final results = await smuleService.searchPerformances(query);
      return results.map((e) => e.toVoxSearchResult(providerId)).toList();
    } catch (e) {
      print('Smule search error: $e');
      return [];
    }
  }

  @override
  Future<String?> resolveStreamUrl(VoxSearchResult result) async {
    try {
      return await smuleService.getMediaUrl(result.url ?? '');
    } catch (e) {
      print('Smule resolve error: $e');
      return null;
    }
  }
}
