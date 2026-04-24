import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/youtube_service.dart';
import '../models/library_song.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final filteredLibraryProvider = FutureProvider<List<LibrarySong>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final ytService = ref.watch(youtubeServiceProvider);

  if (query.isEmpty) {
    // Default to popular Bollywood karaoke
    return ytService.searchSongs('top 10 popular bollywood');
  }

  // Debounce search queries to avoid spamming the YouTube API
  var didDispose = false;
  ref.onDispose(() => didDispose = true);
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  if (didDispose) {
    throw Exception('Search cancelled');
  }

  return ytService.searchSongs(query);
});
