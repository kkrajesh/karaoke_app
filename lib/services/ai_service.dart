import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/settings_provider.dart';

class AiService {
  final Ref ref;
  
  AiService(this.ref);

  Future<String?> _callLlm(String url, String model, List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('$url/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content']?.trim();
      } else {
        print('LLM Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('LLM Request Error: $e');
    }
    return null;
  }

  Future<Map<String, String>?> _standardizeSong(String rawTitle, AppSettings settings) async {
    final systemPrompt = '''You are a strict data extraction assistant.
You will be given a raw song/video title. 
Extract the actual song title, the primary artist/movie, and the likely language from this list: ${settings.aiLanguages}.
Reply ONLY with a raw JSON object (no markdown, no backticks).
Format: {"title": "Clean Song Title", "artist": "Artist Name", "language": "Language"}''';

    final result = await _callLlm(settings.llmUrl, settings.llmModel, [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': 'Raw Title: "$rawTitle"'}
    ]);

    if (result != null) {
      try {
        final cleanJson = result.replaceAll('```json', '').replaceAll('```', '').trim();
        final map = jsonDecode(cleanJson);
        return {
          'title': map['title']?.toString() ?? '',
          'artist': map['artist']?.toString() ?? '',
          'language': map['language']?.toString() ?? 'Unknown',
        };
      } catch (e) {
        print('JSON parsing error for standardization: $e\nRaw Output: $result');
      }
    }
    return null;
  }

  Future<String> _scrapeDuckDuckGo(String query) async {
    try {
      final url = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
      });
      if (response.statusCode == 200) {
        final exp = RegExp(r'class="result__snippet[^>]*>(.*?)</a>', dotAll: true);
        final matches = exp.allMatches(response.body);
        final snippets = matches.map((m) => m.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim()).take(3);
        return snippets.join('\n');
      }
    } catch (e) {
      print('DDG Search error: $e');
    }
    return '';
  }

  Future<String> _fetchWikipediaSummary(String query) async {
    try {
      final url = Uri.parse('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro=1&explaintext=1&titles=${Uri.encodeComponent(query)}');
      final response = await http.get(url, headers: {
        'User-Agent': 'KaraokeApp/1.0 (test@example.com)'
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final page = pages.values.first;
          if (page['extract'] != null && page['pageid'] != -1) {
            final extract = page['extract'].toString();
            // take first 500 characters
            return extract.length > 500 ? extract.substring(0, 500) : extract;
          }
        }
      }
    } catch (e) {
      print('Wiki search error: $e');
    }
    return '';
  }

  Future<String> generateAiTrivia(Song song, {String? customPrompt}) async {
    final settings = ref.read(settingsProvider);
    if (!settings.aiEnabled) {
      return "AI Teleprompter is disabled in Settings.";
    }

    // Step 1: Standardize
    final songInfo = await _standardizeSong(song.title, settings);
    final title = songInfo?['title'] ?? song.title;
    final artist = songInfo?['artist'] ?? 'Unknown Artist';
    
    // Step 2: Information Retrieval
    final ddgQuery = '$title $artist song trivia facts plot';
    final ddgContext = await _scrapeDuckDuckGo(ddgQuery);
    
    final wikiQuery = '$title $artist song';
    final wikiContext = await _fetchWikipediaSummary(wikiQuery);

    final combinedContext = '''
Wikipedia Snippet:
$wikiContext

Search Snippets:
$ddgContext
'''.trim();

    // Step 3: Final Generation
    final systemPrompt = '''You are a musical historian and an energetic karaoke host AI assistant.
Your job is to generate a comprehensive markdown document about a song based on the provided context.
Output exactly this markdown format:

### Host Intro
(Write a fun, punchy 2-sentence intro to hype up the audience. Announce the upcoming singer by name and the song they are singing. Sprinkle in an interesting trivia fact about the song to make it engaging!)

### Song Details
| Field | Details |
|---|---|
| Title | ... |
| Movie/Album | ... |
| Year | ... |
| Singers | ... |
| Main Actors | ... |
| Composer | ... |
| Lyricist | ... |
| Raaga | ... |

### Scene / Plot Context
(Write a paragraph describing the movie scene or the story/theme behind the song)

### Trivia & Anecdotes
- (Bullet point 1)
- (Bullet point 2)
- (Bullet point 3)

Fill in the table with "Unknown" if the information is not present in the context.
Do NOT output anything other than the markdown requested.''';

    final userPrompt = '''
Upcoming Singer: ${song.displaySingerName}
Current Song: "$title" by $artist
${customPrompt != null && customPrompt.isNotEmpty ? '\nSpecial Instructions: $customPrompt\n' : ''}
Background Context:
$combinedContext
''';

    final finalScript = await _callLlm(settings.llmUrl, settings.llmModel, [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt}
    ]);

    if (finalScript != null && finalScript.isNotEmpty) {
      return finalScript;
    }

    return "Failed to generate AI Trivia.";
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref);
});
