import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Use a fixed session ID for simplicity in this demo, or generate one per event
  final String _sessionId = 'current_session';

  // Queue stream
  Stream<List<Song>> getQueue() {
    return _db
        .collection('sessions')
        .doc(_sessionId)
        .collection('queue')
        .orderBy('addedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Song.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Now playing stream
  Stream<Song?> getNowPlaying() {
    return _db
        .collection('sessions')
        .doc(_sessionId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data()!.containsKey('nowPlaying')) {
        final data = snapshot.data()!['nowPlaying'];
        if (data == null) return null;
        return Song.fromMap(Map<String, dynamic>.from(data), 'nowPlaying');
      }
      return null;
    });
  }

  // Add song to queue
  Future<void> addToQueue(Song song) async {
    await _db
        .collection('sessions')
        .doc(_sessionId)
        .collection('queue')
        .add(song.toMap());
  }

  // Pop next song from queue and set as Now Playing
  Future<void> playNext() async {
    final queueDocs = await _db
        .collection('sessions')
        .doc(_sessionId)
        .collection('queue')
        .orderBy('addedAt')
        .limit(1)
        .get();

    if (queueDocs.docs.isNotEmpty) {
      final nextSongDoc = queueDocs.docs.first;
      
      // Transaction to safely pop from queue and set to nowPlaying
      await _db.runTransaction((transaction) async {
        final sessionRef = _db.collection('sessions').doc(_sessionId);
        
        transaction.set(sessionRef, {
          'nowPlaying': nextSongDoc.data()
        }, SetOptions(merge: true));
        
        transaction.delete(nextSongDoc.reference);
      });
    } else {
      // Clear now playing if queue is empty
      await _db.collection('sessions').doc(_sessionId).set({
        'nowPlaying': null
      }, SetOptions(merge: true));
    }
  }

  // Send an emoji reaction
  Future<void> sendReaction(String emoji, String userId) async {
    await _db
        .collection('sessions')
        .doc(_sessionId)
        .collection('reactions')
        .add({
      'emoji': emoji,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Listen to recent reactions
  Stream<List<Map<String, dynamic>>> getReactions() {
    final now = DateTime.now().subtract(const Duration(seconds: 10)); // Only get recent
    return _db
        .collection('sessions')
        .doc(_sessionId)
        .collection('reactions')
        .where('timestamp', isGreaterThanOrEqualTo: now)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
