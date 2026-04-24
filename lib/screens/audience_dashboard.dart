import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../providers/session_state_provider.dart';
import 'player_screen.dart';

class AudienceDashboard extends ConsumerStatefulWidget {
  const AudienceDashboard({super.key});

  @override
  ConsumerState<AudienceDashboard> createState() => _AudienceDashboardState();
}

class _AudienceDashboardState extends ConsumerState<AudienceDashboard> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const GradientText('Audience View', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNowPlaying(),
                const SizedBox(height: 24),
                _buildReactionsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlaying() {
    final nowPlaying = ref.watch(nowPlayingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          nowPlaying != null 
            ? 'Now Playing: ${nowPlaying.requestedByName} - ${nowPlaying.title}' 
            : 'Now Playing: Nobody', 
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentPink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: nowPlaying != null
                ? PlayerScreen(videoId: nowPlaying.videoId, key: ValueKey(nowPlaying.id))
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_external_on, size: 64, color: AppTheme.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for the next singer...',
                          style: TextStyle(fontSize: 24, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audience Reactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight),
          ),
          const SizedBox(height: 16),
          // We can remove the "Live comments will appear here" box from the audience view,
          // since the audience just sends them. But let's leave it as a placeholder for now.
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EmojiBtn('👏', ref),
              _EmojiBtn('🔥', ref),
              _EmojiBtn('🎤', ref),
              _EmojiBtn('😂', ref),
              _EmojiBtn('💖', ref),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Say something encouraging...',
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      ref.read(sessionStateProvider.notifier).sendReaction(value, 'audience');
                      _commentController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  if (_commentController.text.isNotEmpty) {
                    ref.read(sessionStateProvider.notifier).sendReaction(_commentController.text, 'audience');
                    _commentController.clear();
                  }
                },
                icon: const Icon(Icons.send),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _EmojiBtn extends StatelessWidget {
  final String emoji;
  final WidgetRef ref;
  const _EmojiBtn(this.emoji, this.ref);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgInput,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Text(emoji, style: const TextStyle(fontSize: 24)),
        onPressed: () {
          ref.read(sessionStateProvider.notifier).sendReaction(emoji, 'audience');
        },
      ),
    );
  }
}
