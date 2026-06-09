import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vox_player_core/vox_player_core.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  final aiVaultPath = prefs.getString('aiVaultPath') ?? r'C:\Users\rajes\.vox_ai_vault';
  VoxSettingsService.init(
    aiVaultPath: aiVaultPath,
    aiHotZonePath: r'C:\Users\rajes\.vox_ai_hotzone',
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KaraokeApp(),
    ),
  );
}

class KaraokeApp extends StatelessWidget {
  const KaraokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karaoke King',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.unknown,
        },
      ),
    );
  }
}
