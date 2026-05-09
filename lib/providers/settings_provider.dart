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
    );
  }

  Future<void> updateSettings({
    String? eventName,
    String? googleSheetsWebhookUrl,
    String? mmdbPath,
    String? smuleDefaultUsername,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    // We purposefully do not save eventName to prefs so it generates a fresh dynamic name every session
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
