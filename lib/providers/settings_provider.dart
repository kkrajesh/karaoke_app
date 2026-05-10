import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

class AppSettings {
  final String eventName;
  final String googleSheetsWebhookUrl;
  final String mmdbPath;
  final String smuleDefaultUsername;
  
  // AI Settings
  final bool aiEnabled;
  final String llmProvider;
  final String llmUrl;
  final String llmModel;
  final String aiLanguages;

  AppSettings({
    this.eventName = '',
    this.googleSheetsWebhookUrl = '',
    this.mmdbPath = r'C:\Data\Rajesh\Dev\data\MM.DB',
    this.smuleDefaultUsername = '',
    this.aiEnabled = true,
    this.llmProvider = 'LM Studio',
    this.llmUrl = 'http://localhost:1234',
    this.llmModel = 'local-model',
    this.aiLanguages = 'English, Hindi, Tamil, Malayalam, Telugu',
  });

  AppSettings copyWith({
    String? eventName,
    String? googleSheetsWebhookUrl,
    String? mmdbPath,
    String? smuleDefaultUsername,
    bool? aiEnabled,
    String? llmProvider,
    String? llmUrl,
    String? llmModel,
    String? aiLanguages,
  }) {
    return AppSettings(
      eventName: eventName ?? this.eventName,
      googleSheetsWebhookUrl: googleSheetsWebhookUrl ?? this.googleSheetsWebhookUrl,
      mmdbPath: mmdbPath ?? this.mmdbPath,
      smuleDefaultUsername: smuleDefaultUsername ?? this.smuleDefaultUsername,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      llmProvider: llmProvider ?? this.llmProvider,
      llmUrl: llmUrl ?? this.llmUrl,
      llmModel: llmModel ?? this.llmModel,
      aiLanguages: aiLanguages ?? this.aiLanguages,
    );
  }
}

String _getDefaultEventName() {
  final now = DateTime.now();
  final months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final month = months[now.month - 1];
  return 'Karaoke Fun - $month ${now.day}, ${now.year}';
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final defaultName = _getDefaultEventName();
    
    return AppSettings(
      eventName: defaultName,
      googleSheetsWebhookUrl: prefs.getString('googleSheetsWebhookUrl') ?? '',
      mmdbPath: prefs.getString('mmdbPath') ?? r'C:\Data\Rajesh\Dev\data\MM.DB',
      smuleDefaultUsername: prefs.getString('smuleDefaultUsername') ?? '',
      aiEnabled: prefs.getBool('aiEnabled') ?? true,
      llmProvider: prefs.getString('llmProvider') ?? 'LM Studio',
      llmUrl: prefs.getString('llmUrl') ?? 'http://localhost:1234',
      llmModel: prefs.getString('llmModel') ?? 'local-model',
      aiLanguages: prefs.getString('aiLanguages') ?? 'English, Hindi, Tamil, Malayalam, Telugu',
    );
  }

  Future<void> updateSettings({
    String? eventName,
    String? googleSheetsWebhookUrl,
    String? mmdbPath,
    String? smuleDefaultUsername,
    bool? aiEnabled,
    String? llmProvider,
    String? llmUrl,
    String? llmModel,
    String? aiLanguages,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    // We purposefully do not save eventName to prefs so it generates a fresh dynamic name every session
    if (googleSheetsWebhookUrl != null) await prefs.setString('googleSheetsWebhookUrl', googleSheetsWebhookUrl);
    if (mmdbPath != null) await prefs.setString('mmdbPath', mmdbPath);
    if (smuleDefaultUsername != null) await prefs.setString('smuleDefaultUsername', smuleDefaultUsername);
    if (aiEnabled != null) await prefs.setBool('aiEnabled', aiEnabled);
    if (llmProvider != null) await prefs.setString('llmProvider', llmProvider);
    if (llmUrl != null) await prefs.setString('llmUrl', llmUrl);
    if (llmModel != null) await prefs.setString('llmModel', llmModel);
    if (aiLanguages != null) await prefs.setString('aiLanguages', aiLanguages);

    state = state.copyWith(
      eventName: eventName,
      googleSheetsWebhookUrl: googleSheetsWebhookUrl,
      mmdbPath: mmdbPath,
      smuleDefaultUsername: smuleDefaultUsername,
      aiEnabled: aiEnabled,
      llmProvider: llmProvider,
      llmUrl: llmUrl,
      llmModel: llmModel,
      aiLanguages: aiLanguages,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
