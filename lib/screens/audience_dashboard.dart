import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../providers/session_state_provider.dart';

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
                _buildReactionsCard(),
                const SizedBox(height: 16),
                _buildNowPlaying(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlaying() {
    final nowPlaying = ref.watch(nowPlayingProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.bgCard, AppTheme.bgDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.mic_external_on, size: 48, color: AppTheme.accentPink),
          const SizedBox(height: 16),
          if (nowPlaying != null) ...[
            const Text(
              'NOW PLAYING',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight, letterSpacing: 2.0),
            ),
            const SizedBox(height: 8),
            Text(
              nowPlaying.requestedByName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'singing "${nowPlaying.title}"',
              style: const TextStyle(fontSize: 18, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const Text(
              'Stage is Empty',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for the next singer...',
              style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
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
                      ref.read(sessionStateProvider.notifier).sendReaction('audience', value, isEmoji: false);
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
                    ref.read(sessionStateProvider.notifier).sendReaction('audience', _commentController.text, isEmoji: false);
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
          ref.read(sessionStateProvider.notifier).sendReaction('audience', emoji);
        },
      ),
    );
  }
}
