import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import 'dart:math';

class AiService {
  final List<String> _mockFacts = [
    "Did you know this song topped the charts in 14 different countries?",
    "Fun fact: the artist recorded the vocals for this in a single take!",
    "Rumor has it this song was originally written for a different artist.",
    "This track features a hidden background vocal track that fans didn't discover for years.",
    "The iconic guitar riff in this song was created accidentally during a warm-up session.",
    "This was the most requested song at karaoke bars worldwide in 2019."
  ];

  Future<String> generateHostFact(Song currentSong, Song? nextSong) async {
    // Simulate network delay for AI generation
    await Future.delayed(const Duration(seconds: 1));
    
    final random = Random();
    final fact = _mockFacts[random.nextInt(_mockFacts.length)];
    
    if (nextSong != null) {
      return "🎤 Currently singing: ${currentSong.requestedByName}\n\n🤖 AI Fun Fact about '${currentSong.title}': $fact\n\nUp Next: ${nextSong.requestedByName} getting ready to sing '${nextSong.title}'.";
    } else {
      return "🎤 Currently singing: ${currentSong.requestedByName}\n\n🤖 AI Fun Fact about '${currentSong.title}': $fact\n\nThe stage is empty after this! Someone queue up a song!";
    }
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});
