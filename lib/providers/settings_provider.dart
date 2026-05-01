import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

class AppSettings {
  final String eventName;
  final String googleSheetsWebhookUrl;
  final String mmdbPath;

  AppSettings({
    this.eventName = '',
    this.googleSheetsWebhookUrl = '',
    this.mmdbPath = r'C:\Data\Rajesh\Dev\data\MM.DB', // Default hardcoded path
  });

  AppSettings copyWith({
    String? eventName,
    String? googleSheetsWebhookUrl,
    String? mmdbPath,
  }) {
    return AppSettings(
      eventName: eventName ?? this.eventName,
      googleSheetsWebhookUrl: googleSheetsWebhookUrl ?? this.googleSheetsWebhookUrl,
      mmdbPath: mmdbPath ?? this.mmdbPath,
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
    );
  }

  Future<void> updateSettings({
    String? eventName,
    String? googleSheetsWebhookUrl,
    String? mmdbPath,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (eventName != null) await prefs.setString('eventName', eventName);
    if (googleSheetsWebhookUrl != null) await prefs.setString('googleSheetsWebhookUrl', googleSheetsWebhookUrl);
    if (mmdbPath != null) await prefs.setString('mmdbPath', mmdbPath);

    state = state.copyWith(
      eventName: eventName,
      googleSheetsWebhookUrl: googleSheetsWebhookUrl,
      mmdbPath: mmdbPath,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
