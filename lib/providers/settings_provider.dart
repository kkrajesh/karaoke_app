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

  AppSettings({
    this.eventName = '',
    this.googleSheetsWebhookUrl = '',
    this.mmdbPath = r'C:\Data\Rajesh\Dev\data\MM.DB',
    this.smuleDefaultUsername = '',
  });

  AppSettings copyWith({
    String? eventName,
    String? googleSheetsWebhookUrl,
    String? mmdbPath,
    String? smuleDefaultUsername,
  }) {
    return AppSettings(
      eventName: eventName ?? this.eventName,
      googleSheetsWebhookUrl: googleSheetsWebhookUrl ?? this.googleSheetsWebhookUrl,
      mmdbPath: mmdbPath ?? this.mmdbPath,
      smuleDefaultUsername: smuleDefaultUsername ?? this.smuleDefaultUsername,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      eventName: prefs.getString('eventName') ?? '',
      googleSheetsWebhookUrl: prefs.getString('googleSheetsWebhookUrl') ?? '',
      mmdbPath: prefs.getString('mmdbPath') ?? r'C:\Data\Rajesh\Dev\data\MM.DB',
      smuleDefaultUsername: prefs.getString('smuleDefaultUsername') ?? '',
    );
  }

  Future<void> updateSettings({
    String? eventName,
    String? googleSheetsWebhookUrl,
    String? mmdbPath,
    String? smuleDefaultUsername,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (eventName != null) await prefs.setString('eventName', eventName);
    if (googleSheetsWebhookUrl != null) await prefs.setString('googleSheetsWebhookUrl', googleSheetsWebhookUrl);
    if (mmdbPath != null) await prefs.setString('mmdbPath', mmdbPath);
    if (smuleDefaultUsername != null) await prefs.setString('smuleDefaultUsername', smuleDefaultUsername);

    state = state.copyWith(
      eventName: eventName,
      googleSheetsWebhookUrl: googleSheetsWebhookUrl,
      mmdbPath: mmdbPath,
      smuleDefaultUsername: smuleDefaultUsername,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
