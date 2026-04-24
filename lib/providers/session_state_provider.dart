import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';

class SessionState {
  final List<Song> queue;
  final Song? nowPlaying;
  final List<Map<String, dynamic>> reactions;

  SessionState({
    this.queue = const [],
    this.nowPlaying,
    this.reactions = const [],
  });

  SessionState copyWith({
    List<Song>? queue,
    Song? nowPlaying,
    List<Map<String, dynamic>>? reactions,
  }) {
    return SessionState(
      queue: queue ?? this.queue,
      nowPlaying: nowPlaying ?? this.nowPlaying,
      reactions: reactions ?? this.reactions,
    );
  }
  
  SessionState copyWithNullableNowPlaying({
    List<Song>? queue,
    Song? nowPlaying,
    bool clearNowPlaying = false,
  }) {
    return SessionState(
      queue: queue ?? this.queue,
      nowPlaying: clearNowPlaying ? null : (nowPlaying ?? this.nowPlaying),
      reactions: this.reactions,
    );
  }
}

class SessionStateNotifier extends Notifier<SessionState> {
  Timer? _pollTimer;

  @override
  SessionState build() {
    if (kIsWeb) {
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
      final queueRes = await http.get(Uri.parse('/queue'));
      if (queueRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(queueRes.body);
        final queue = data.map((e) => Song.fromMap(e, e['id'] ?? '')).toList();
        state = state.copyWith(queue: queue);
      }

      final npRes = await http.get(Uri.parse('/now-playing'));
      if (npRes.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(npRes.body);
        final nowPlaying = data.isEmpty ? null : Song.fromMap(data, data['id'] ?? '');
        state = state.copyWithNullableNowPlaying(nowPlaying: nowPlaying, clearNowPlaying: data.isEmpty);
      }

      final reactRes = await http.get(Uri.parse('/reactions'));
      if (reactRes.statusCode == 200) {
        final List<dynamic> rdata = jsonDecode(reactRes.body);
        final reactions = rdata.map((r) => r as Map<String, dynamic>).toList();
        state = state.copyWith(reactions: reactions);
      }
    } catch (e) {
      print('Network sync error: $e');
    }
  }

  Future<void> addToQueue(Song song) async {
    if (kIsWeb) {
      try {
        await http.post(
          Uri.parse('/queue'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(song.toMap()),
        );
        // Will sync on next poll, but we can optimistically update
        state = state.copyWith(
          queue: [...state.queue, song]..sort((a, b) => a.addedAt.compareTo(b.addedAt)),
        );
      } catch (e) {
        print('Error posting to queue: $e');
      }
    } else {
      state = state.copyWith(
        queue: [...state.queue, song]..sort((a, b) => a.addedAt.compareTo(b.addedAt)),
      );
    }
  }

  Future<void> playNext() async {
    if (kIsWeb) {
      try {
        await http.post(Uri.parse('/play-next'));
      } catch (e) {
        print('Error posting playNext: $e');
      }
      return; // The state will update on the next poll
    }

    if (state.queue.isEmpty) {
      state = state.copyWithNullableNowPlaying(clearNowPlaying: true);
      return;
    }

    final nextSong = state.queue.first;
    final remainingQueue = state.queue.sublist(1);

    state = state.copyWithNullableNowPlaying(
      queue: remainingQueue,
      nowPlaying: nextSong,
    );
  }

  Future<void> removeFromQueue(String songId) async {
    if (kIsWeb) {
      try {
        await http.delete(Uri.parse('/queue/$songId'));
      } catch (e) {
        print('Error deleting from queue: $e');
      }
      return; // Will sync on next poll
    }

    state = state.copyWith(
      queue: state.queue.where((song) => song.id != songId).toList(),
    );
  }

  Future<void> sendReaction(String emoji, String userId) async {
    final reaction = {
      'emoji': emoji,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (kIsWeb) {
      try {
        await http.post(
          Uri.parse('/reactions'),
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
      
      state = state.copyWith(reactions: updatedReactions);
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
