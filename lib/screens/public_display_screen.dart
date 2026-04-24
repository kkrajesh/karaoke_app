import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_state_provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class PublicDisplayScreen extends ConsumerWidget {
  const PublicDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final reactions = ref.watch(sessionStateProvider).reactions;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Screen Video Player
          if (nowPlaying != null)
            Positioned.fill(
              child: PlayerScreen(
                videoId: nowPlaying.videoId,
                key: ValueKey(nowPlaying.id),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_external_on, size: 100, color: AppTheme.textMuted),
                  SizedBox(height: 24),
                  Text(
                    'Karaoke Night Live',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.accentPink),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Waiting for the next singer...',
                    style: TextStyle(fontSize: 24, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

          // 2. Now Playing Banner
          if (nowPlaying != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  '🎤 ${nowPlaying.requestedByName} is singing: ${nowPlaying.title}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // 3. Live Reactions Overlay (Livestream style)
          Positioned(
            bottom: 24,
            right: 24,
            width: 350,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: reactions.take(15).map((r) {
                  final text = r['emoji'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, color: AppTheme.textMuted, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            text,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Back Button for the Host
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
              onPressed: () {
                ref.read(appStateProvider.notifier).clearRole();
              },
            ),
          ),
        ],
      ),
    );
  }
}
