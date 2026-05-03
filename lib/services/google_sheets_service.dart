import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/settings_provider.dart';

class GoogleSheetsService {
  final String webhookUrl;
  final String eventName;

  GoogleSheetsService({
    required this.webhookUrl,
    required this.eventName,
  });

  Future<void> logPerformance(Song song, Map<String, int> emojiCounts) async {
    if (webhookUrl.isEmpty) {
      print('Google Sheets Webhook URL is not configured. Skipping log.');
      return;
    }

    try {
      // Format the emojis to match the requested style: "🔥x5, 👏x3"
      final summaryParts = emojiCounts.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.key}x${e.value}')
          .toList();
      
      final reactionSummary = summaryParts.isEmpty ? 'None' : summaryParts.join(', ');
      final totalReactions = emojiCounts.values.fold(0, (sum, count) => sum + count);
      
      final timestamp = DateTime.now().toIso8601String();

      final payload = {
        'songId': song.id,
        'timestamp': timestamp,
        'eventName': eventName,
        'singerName': song.requestedByName,
        'songTitle': song.title,
        'songUrl': song.videoId.startsWith('https://www.smule.com') ? song.videoId : (song.isLocal ? song.videoId : 'https://www.youtube.com/watch?v=${song.videoId}'),
        'sourceType': song.videoId.startsWith('https://www.smule.com') ? 'Smule' : (song.isLocal ? 'Local' : 'YouTube'),
        'reactionSummary': reactionSummary,
        'totalReactions': totalReactions,
      };

      print('[GoogleSheetsService] Logging performance to sheet: ${song.title} by ${song.requestedByName}');

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        print('[GoogleSheetsService] Successfully logged performance.');
      } else {
        print('[GoogleSheetsService] Failed to log. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('[GoogleSheetsService] Error logging to Google Sheets: $e');
    }
  }
}

final googleSheetsServiceProvider = Provider<GoogleSheetsService>((ref) {
  final settings = ref.watch(settingsProvider);
  return GoogleSheetsService(
    webhookUrl: settings.googleSheetsWebhookUrl,
    eventName: settings.eventName,
  );
});
