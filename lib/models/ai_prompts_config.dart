import 'dart:convert';

class AiPromptsConfig {
  final String triviaSystemPrompt;
  final String triviaUserPromptTemplate;
  final String standardizationSystemPrompt;
  final double temperature;

  AiPromptsConfig({
    required this.triviaSystemPrompt,
    required this.triviaUserPromptTemplate,
    required this.standardizationSystemPrompt,
    required this.temperature,
  });

  factory AiPromptsConfig.defaultConfig() {
    return AiPromptsConfig(
      temperature: 0.7,
      standardizationSystemPrompt: '''You are a strict data extraction assistant.
You will be given a raw song/video title. 
Extract the actual song title, the primary artist/movie, and the likely language from this list: {{languages}}.
Reply ONLY with a raw JSON object (no markdown, no backticks).
Format: {"title": "Clean Song Title", "artist": "Artist Name", "language": "Language"}''',
      triviaSystemPrompt: '''You are a musical historian and an energetic karaoke host AI assistant.
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
Do NOT output anything other than the markdown requested.''',
      triviaUserPromptTemplate: '''Upcoming Singer: {{singer}}
Current Song: "{{title}}" by {{artist}}
{{custom_prompt}}

Background Context:
{{context}}'''
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'triviaSystemPrompt': triviaSystemPrompt,
      'triviaUserPromptTemplate': triviaUserPromptTemplate,
      'standardizationSystemPrompt': standardizationSystemPrompt,
      'temperature': temperature,
    };
  }

  factory AiPromptsConfig.fromMap(Map<String, dynamic> map) {
    return AiPromptsConfig(
      triviaSystemPrompt: map['triviaSystemPrompt'] ?? AiPromptsConfig.defaultConfig().triviaSystemPrompt,
      triviaUserPromptTemplate: map['triviaUserPromptTemplate'] ?? AiPromptsConfig.defaultConfig().triviaUserPromptTemplate,
      standardizationSystemPrompt: map['standardizationSystemPrompt'] ?? AiPromptsConfig.defaultConfig().standardizationSystemPrompt,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
    );
  }

  String toJson() => json.encode(toMap());

  factory AiPromptsConfig.fromJson(String source) => AiPromptsConfig.fromMap(json.decode(source));

  AiPromptsConfig copyWith({
    String? triviaSystemPrompt,
    String? triviaUserPromptTemplate,
    String? standardizationSystemPrompt,
    double? temperature,
  }) {
    return AiPromptsConfig(
      triviaSystemPrompt: triviaSystemPrompt ?? this.triviaSystemPrompt,
      triviaUserPromptTemplate: triviaUserPromptTemplate ?? this.triviaUserPromptTemplate,
      standardizationSystemPrompt: standardizationSystemPrompt ?? this.standardizationSystemPrompt,
      temperature: temperature ?? this.temperature,
    );
  }
}
