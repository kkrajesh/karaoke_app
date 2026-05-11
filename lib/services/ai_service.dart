import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/ai_prompts_config.dart';
import '../providers/settings_provider.dart';

class AiService {
  final Ref ref;
  
  AiService(this.ref);

  Future<String?> _callLlm(String url, String model, List<Map<String, String>> messages, double temperature) async {
    try {
      final response = await http.post(
        Uri.parse('$url/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
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

  Future<AiPromptsConfig> _getPromptsConfig(AppSettings settings) async {
    try {
      final dbDir = p.dirname(settings.mmdbPath);
      final file = File(p.join(dbDir, 'ai_prompts.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        return AiPromptsConfig.fromJson(content);
      } else {
        final config = AiPromptsConfig.defaultConfig();
        await file.writeAsString(config.toJson());
        return config;
      }
    } catch (e) {
      print('Error reading ai_prompts.json: $e');
      return AiPromptsConfig.defaultConfig();
    }
  }

  Future<Map<String, String>?> _standardizeSong(String rawTitle, AppSettings settings) async {
    final config = await _getPromptsConfig(settings);
    final systemPrompt = config.standardizationSystemPrompt.replaceAll('{{languages}}', settings.aiLanguages);

    final result = await _callLlm(settings.llmUrl, settings.llmModel, [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': 'Raw Title: "$rawTitle"'}
    ], config.temperature);

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

    final config = await _getPromptsConfig(settings);

    // Step 3: Final Generation
    final systemPrompt = config.triviaSystemPrompt;

    final userPrompt = config.triviaUserPromptTemplate
        .replaceAll('{{singer}}', song.displaySingerName)
        .replaceAll('{{title}}', title)
        .replaceAll('{{artist}}', artist)
        .replaceAll('{{custom_prompt}}', customPrompt != null && customPrompt.isNotEmpty ? 'Special Instructions: $customPrompt' : '')
        .replaceAll('{{context}}', combinedContext);

    final finalScript = await _callLlm(settings.llmUrl, settings.llmModel, [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt}
    ], config.temperature);

    if (finalScript != null && finalScript.isNotEmpty) {
      return finalScript;
    }

    return "Failed to generate AI Trivia.";
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref);
});
