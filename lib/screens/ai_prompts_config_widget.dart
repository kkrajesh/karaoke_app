import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/ai_prompts_config.dart';
import '../providers/settings_provider.dart';

class AiPromptsConfigWidget extends ConsumerStatefulWidget {
  const AiPromptsConfigWidget({super.key});

  @override
  ConsumerState<AiPromptsConfigWidget> createState() => _AiPromptsConfigWidgetState();
}

class _AiPromptsConfigWidgetState extends ConsumerState<AiPromptsConfigWidget> {
  AiPromptsConfig? _config;
  bool _isLoading = true;
  
  final _triviaSystemCtrl = TextEditingController();
  final _triviaUserCtrl = TextEditingController();
  final _standardizationSystemCtrl = TextEditingController();
  double _temperature = 0.7;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final settings = ref.read(settingsProvider);
    try {
      final dbDir = p.dirname(settings.mmdbPath);
      final file = File(p.join(dbDir, 'ai_prompts.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        _config = AiPromptsConfig.fromJson(content);
      } else {
        _config = AiPromptsConfig.defaultConfig();
        await file.writeAsString(_config!.toJson());
      }
    } catch (e) {
      print('Error loading ai_prompts.json: $e');
      _config = AiPromptsConfig.defaultConfig();
    }
    
    if (mounted) {
      setState(() {
        _triviaSystemCtrl.text = _config!.triviaSystemPrompt;
        _triviaUserCtrl.text = _config!.triviaUserPromptTemplate;
        _standardizationSystemCtrl.text = _config!.standardizationSystemPrompt;
        _temperature = _config!.temperature;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    
    final updatedConfig = _config!.copyWith(
      triviaSystemPrompt: _triviaSystemCtrl.text,
      triviaUserPromptTemplate: _triviaUserCtrl.text,
      standardizationSystemPrompt: _standardizationSystemCtrl.text,
      temperature: _temperature,
    );

    final settings = ref.read(settingsProvider);
    try {
      final dbDir = p.dirname(settings.mmdbPath);
      final file = File(p.join(dbDir, 'ai_prompts.json'));
      await file.writeAsString(updatedConfig.toJson());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Prompts saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save AI Prompts: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _triviaSystemCtrl.dispose();
    _triviaUserCtrl.dispose();
    _standardizationSystemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Creativity / Randomness (Temperature)', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text(_temperature.toStringAsFixed(1)),
            Expanded(
              child: Slider(
                value: _temperature,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: _temperature.toStringAsFixed(1),
                onChanged: (val) {
                  setState(() {
                    _temperature = val;
                  });
                },
              ),
            ),
            const Text('High', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Trivia System Prompt', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _triviaSystemCtrl,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const Text('Trivia User Prompt Template', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Variables: {{singer}}, {{title}}, {{artist}}, {{context}}, {{custom_prompt}}', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _triviaUserCtrl,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const Text('Standardization System Prompt', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Variables: {{languages}}', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _standardizationSystemCtrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Prompts'),
          onPressed: _saveConfig,
        ),
        const SizedBox(height: 8),
        const Text('Note: You can also edit ai_prompts.json directly in your MM.DB folder!', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
      ],
    );
  }
}
