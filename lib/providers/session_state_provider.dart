import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/app_state_provider.dart';
import '../services/ai_service.dart';

class SessionState {
  final List<Song> queue;
  final Song? nowPlaying;
  final List<Map<String, dynamic>> reactions;
  final Map<String, int> emojiCounts;
  final String? funFact;
  final String? announcement;
  final int? countdownEndTime; // Unix timestamp in milliseconds

  SessionState({
    this.queue = const [],
    this.nowPlaying,
    this.reactions = const [],
    this.emojiCounts = const {},
    this.funFact,
    this.announcement,
    this.countdownEndTime,
  });

  SessionState copyWith({
    List<Song>? queue,
    Song? nowPlaying,
    List<Map<String, dynamic>>? reactions,
    Map<String, int>? emojiCounts,
    String? funFact,
    String? announcement,
    int? countdownEndTime,
    bool clearAnnouncement = false,
    bool clearCountdown = false,
  }) {
    return SessionState(
      queue: queue ?? this.queue,
      nowPlaying: nowPlaying ?? this.nowPlaying,
      reactions: reactions ?? this.reactions,
      emojiCounts: emojiCounts ?? this.emojiCounts,
      funFact: funFact ?? this.funFact,
      announcement: clearAnnouncement ? null : (announcement ?? this.announcement),
      countdownEndTime: clearCountdown ? null : (countdownEndTime ?? this.countdownEndTime),
    );
  }
  
  SessionState copyWithNullableNowPlaying({
    List<Song>? queue,
    Song? nowPlaying,
    bool clearNowPlaying = false,
    bool clearReactions = false,
    String? funFact,
    String? announcement,
    int? countdownEndTime,
  }) {
    return SessionState(
      queue: queue ?? this.queue,
      nowPlaying: clearNowPlaying ? null : (nowPlaying ?? this.nowPlaying),
      reactions: clearReactions ? [] : this.reactions,
      emojiCounts: clearReactions ? {} : this.emojiCounts,
      funFact: funFact ?? this.funFact,
      announcement: announcement ?? this.announcement,
      countdownEndTime: countdownEndTime ?? this.countdownEndTime,
    );
  }
}

class SessionStateNotifier extends Notifier<SessionState> {
  Timer? _pollTimer;

  bool get _isClient => kIsWeb || ref.read(clientHostIpProvider) != null;
  String get _baseUrl {
    if (kIsWeb) return '';
    final ip = ref.read(clientHostIpProvider);
    return ip != null ? 'http://$ip:8080' : '';
  }

  @override
  SessionState build() {
    // Watch the clientHostIpProvider so that changing the IP resets the state and polling
    ref.watch(clientHostIpProvider);
    
    if (_isClient) {
      _startPolling();
    }
    
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    
    return SessionState();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
       _fetchStateFromServer();
    });
    // Fetch immediately
    _fetchStateFromServer();
  }

  Future<void> _fetchStateFromServer() async {
    try {
      final queueRes = await http.get(Uri.parse('$_baseUrl/queue'));
      if (queueRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(queueRes.body);
        final queue = data.map((e) => Song.fromMap(e, e['id'] ?? '')).toList();
        state = state.copyWith(queue: queue);
      }

      final npRes = await http.get(Uri.parse('$_baseUrl/now-playing'));
      if (npRes.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(npRes.body);
        final nowPlaying = data.isEmpty ? null : Song.fromMap(data, data['id'] ?? '');
        state = state.copyWithNullableNowPlaying(nowPlaying: nowPlaying, clearNowPlaying: data.isEmpty);
      }

      final reactRes = await http.get(Uri.parse('$_baseUrl/reactions'));
      if (reactRes.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(reactRes.body);
        final List<dynamic> rdata = responseData['reactions'] ?? [];
        final Map<String, dynamic> countsData = responseData['emojiCounts'] ?? {};
        
        final reactions = rdata.map((r) => r as Map<String, dynamic>).toList();
        final emojiCounts = countsData.map((k, v) => MapEntry(k, v as int));
        
        state = state.copyWith(reactions: reactions, emojiCounts: emojiCounts);
      }

      final displayRes = await http.get(Uri.parse('$_baseUrl/display-state'));
      if (displayRes.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(displayRes.body);
        state = state.copyWith(
          announcement: data['announcement'],
          clearAnnouncement: data['announcement'] == null,
          countdownEndTime: data['countdownEndTime'],
          clearCountdown: data['countdownEndTime'] == null,
        );
      }
    } catch (e) {
      print('Network sync error: $e');
    }
  }

  Future<void> addToQueue(Song song) async {
    // Sort active queue by time, but keep pending requests at the very end
    int _sortQueue(Song a, Song b) {
      if (a.isRequest && !b.isRequest) return 1;
      if (!a.isRequest && b.isRequest) return -1;
      return a.addedAt.compareTo(b.addedAt);
    }

    if (_isClient) {
      try {
        http.post(
          Uri.parse('$_baseUrl/queue'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(song.toMap()),
        );
        // Will sync on next poll, but we can optimistically update
        state = state.copyWith(
          queue: [...state.queue, song]..sort(_sortQueue),
        );
      } catch (e) {
        print('Error posting to queue: $e');
      }
    } else {
      state = state.copyWith(
        queue: [...state.queue, song]..sort(_sortQueue),
      );
    }
  }

  void approveRequest(String id, {String? assignedSinger}) {
    int _sortQueue(Song a, Song b) {
      if (a.isRequest && !b.isRequest) return 1;
      if (!a.isRequest && b.isRequest) return -1;
      return a.addedAt.compareTo(b.addedAt);
    }

    if (_isClient) {
      if (assignedSinger != null) {
        http.put(
          Uri.parse('$_baseUrl/queue/$id/approve'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'assignedSinger': assignedSinger}),
        );
      } else {
        http.put(Uri.parse('$_baseUrl/queue/$id/approve'));
      }
      return;
    }

    final idx = state.queue.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final song = state.queue[idx];
      final approvedSong = Song(
        id: song.id,
        title: song.title,
        videoId: song.videoId,
        isLocal: song.isLocal,
        requestedBy: song.requestedBy,
        requestedByName: assignedSinger ?? song.requestedByName,
        addedAt: DateTime.now(), // Move to end of active queue
        isRequest: false,
        requestedFor: song.requestedFor,
        dedication: song.dedication,
      );
      
      final newQueue = List<Song>.from(state.queue);
      newQueue[idx] = approvedSong;
      
      newQueue.sort(_sortQueue);
      state = state.copyWith(queue: newQueue);
    }
  }

  Future<void> playNext() async {
    if (_isClient) {
      try {
        await http.post(Uri.parse('$_baseUrl/play-next'));
      } catch (e) {
        print('Error posting playNext: $e');
      }
      return; // The state will update on the next poll
    }

    final activeQueue = state.queue.where((s) => !s.isRequest).toList();
    final pendingRequests = state.queue.where((s) => s.isRequest).toList();

    if (activeQueue.isEmpty) {
      state = state.copyWithNullableNowPlaying(clearNowPlaying: true, funFact: null);
      return;
    }

    final nextSong = activeQueue.first;
    final remainingActive = activeQueue.sublist(1);
    final upNext = remainingActive.isNotEmpty ? remainingActive.first : null;
    
    final newTotalQueue = [...remainingActive, ...pendingRequests];

    // First, clear the current song to force the player to unmount safely
    state = state.copyWithNullableNowPlaying(
      queue: newTotalQueue,
      clearNowPlaying: true,
      clearReactions: true,
      funFact: 'Loading next singer...',
    );

    // Wait a moment for the GPU to flush the old video texture
    await Future.delayed(const Duration(milliseconds: 600));

    // Now push the new song
    state = state.copyWithNullableNowPlaying(
      nowPlaying: nextSong,
      clearReactions: false,
      funFact: 'Generating AI Fact...',
    );

    // Fetch the fun fact asynchronously
    final aiService = ref.read(aiServiceProvider);
    final fact = await aiService.generateHostFact(nextSong, upNext);
    
    // Check if the song hasn't changed while we were fetching
    if (state.nowPlaying?.id == nextSong.id) {
      state = state.copyWith(funFact: fact);
    }
  }

  Future<void> removeFromQueue(String songId) async {
    if (_isClient) {
      try {
        await http.delete(Uri.parse('$_baseUrl/queue/$songId'));
      } catch (e) {
        print('Error deleting from queue: $e');
      }
      return; // Will sync on next poll
    }

    state = state.copyWith(
      queue: state.queue.where((song) => song.id != songId).toList(),
    );
  }

  void nudgeRequest(String id, int direction) {
    if (_isClient) return; // Only host
    
    int _sortQueue(Song a, Song b) {
      if (a.isRequest && !b.isRequest) return 1;
      if (!a.isRequest && b.isRequest) return -1;
      return a.addedAt.compareTo(b.addedAt);
    }

    final requests = state.queue.where((s) => s.isRequest).toList();
    final idx = requests.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    
    if (direction < 0 && idx > 0) {
      // Swap addedAt with the one above it
      final current = requests[idx];
      final above = requests[idx - 1];
      final tempTime = current.addedAt;
      
      final updatedCurrent = current.copyWith(addedAt: above.addedAt);
      final updatedAbove = above.copyWith(addedAt: tempTime);
      
      final newQueue = List<Song>.from(state.queue);
      newQueue[newQueue.indexWhere((s) => s.id == current.id)] = updatedCurrent;
      newQueue[newQueue.indexWhere((s) => s.id == above.id)] = updatedAbove;
      
      state = state.copyWith(queue: newQueue..sort(_sortQueue));
    } else if (direction > 0 && idx < requests.length - 1) {
      // Swap addedAt with the one below it
      final current = requests[idx];
      final below = requests[idx + 1];
      final tempTime = current.addedAt;
      
      final updatedCurrent = current.copyWith(addedAt: below.addedAt);
      final updatedBelow = below.copyWith(addedAt: tempTime);
      
      final newQueue = List<Song>.from(state.queue);
      newQueue[newQueue.indexWhere((s) => s.id == current.id)] = updatedCurrent;
      newQueue[newQueue.indexWhere((s) => s.id == below.id)] = updatedBelow;
      
      state = state.copyWith(queue: newQueue..sort(_sortQueue));
    }
  }

  void updateRequestNote(String id, String note) {
    if (_isClient) return; // Only host
    
    final idx = state.queue.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final newQueue = List<Song>.from(state.queue);
      newQueue[idx] = newQueue[idx].copyWith(hostNote: note);
      state = state.copyWith(queue: newQueue);
    }
  }

  Future<void> pushAnnouncement(String? message) async {
    if (_isClient) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/display-state/announcement'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'announcement': message}),
        );
      } catch (e) {
        print('Error posting announcement: $e');
      }
    } else {
      state = state.copyWith(announcement: message, clearAnnouncement: message == null);
    }
  }

  Future<void> pushCountdown(int? seconds) async {
    final endTime = seconds != null ? DateTime.now().millisecondsSinceEpoch + (seconds * 1000) : null;
    if (_isClient) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/display-state/countdown'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'countdownEndTime': endTime}),
        );
      } catch (e) {
        print('Error posting countdown: $e');
      }
    } else {
      state = state.copyWith(countdownEndTime: endTime, clearCountdown: endTime == null);
    }
  }

  Future<void> sendReaction(String user, dynamic reactionValue, {bool isEmoji = true}) async {
    final reaction = {
      'user': user,
      'value': reactionValue,
      'isEmoji': isEmoji,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_isClient) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/reactions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(reaction),
        );
      } catch (e) {
        print('Error posting reaction: $e');
      }
    } else {
      var updatedReactions = [...state.reactions, reaction];
      if (updatedReactions.length > 20) {
        updatedReactions = updatedReactions.sublist(updatedReactions.length - 20);
      }
      
      Map<String, int>? updatedCounts;
      if (isEmoji) {
        final key = reactionValue.toString();
        updatedCounts = Map<String, int>.from(state.emojiCounts);
        updatedCounts[key] = (updatedCounts[key] ?? 0) + 1;
      }
      
      state = state.copyWith(
        reactions: updatedReactions,
        emojiCounts: updatedCounts,
      );
    }
  }
}

final sessionStateProvider = NotifierProvider<SessionStateNotifier, SessionState>(() {
  return SessionStateNotifier();
});

// Helper providers to mimic the old streams
final queueProvider = Provider<List<Song>>((ref) {
  return ref.watch(sessionStateProvider).queue;
});

final nowPlayingProvider = Provider<Song?>((ref) {
  return ref.watch(sessionStateProvider).nowPlaying;
});
