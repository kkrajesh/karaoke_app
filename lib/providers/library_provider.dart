import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/youtube_service.dart';
import '../services/media_monkey_service.dart';
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

class SelectedSourcesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'YouTube', 'MediaMonkey'};

  void setSources(Set<String> sources) {
    state = Set.from(sources);
  }
}

final selectedSourcesProvider = NotifierProvider<SelectedSourcesNotifier, Set<String>>(() {
  return SelectedSourcesNotifier();
});

final filteredLibraryProvider = FutureProvider<List<LibrarySong>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final ytService = ref.watch(youtubeServiceProvider);
  final mmService = ref.watch(mediaMonkeyServiceProvider);

  final selectedSources = ref.watch(selectedSourcesProvider);

  if (query.isEmpty) {
    // Default to popular Bollywood karaoke + local search
    List<LibrarySong> localResults = [];
    List<LibrarySong> ytResults = [];
    
    if (selectedSources.contains('YouTube')) {
      ytResults = await ytService.searchSongs('top 10 popular bollywood');
    }
    if (selectedSources.contains('MediaMonkey')) {
      localResults = await mmService.searchSongs('karaoke'); 
    }
    return [...localResults, ...ytResults];
  }

  // Debounce search queries to avoid spamming the YouTube API
  var didDispose = false;
  ref.onDispose(() => didDispose = true);
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  if (didDispose) {
    throw Exception('Search cancelled');
  }

  List<LibrarySong> finalResults = [];

  // Search based on selected sources
  final List<Future<void>> futures = [];

  if (selectedSources.contains('MediaMonkey')) {
    futures.add(mmService.searchSongs(query).then((res) => finalResults.addAll(res)));
  }
  if (selectedSources.contains('YouTube')) {
    futures.add(ytService.searchSongs(query).then((res) => finalResults.addAll(res)));
  }

  await Future.wait(futures);

  return finalResults;
});
