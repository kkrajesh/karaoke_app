import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../providers/session_state_provider.dart';
import '../models/song.dart';
import '../models/library_song.dart';
import '../widgets/song_library.dart';
import '../widgets/reaction_pad.dart';
import '../providers/settings_provider.dart';

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
    final settingsName = ref.watch(settingsProvider).eventName;
    final sessionName = ref.watch(sessionStateProvider).eventName;
    final eventName = settingsName.isNotEmpty ? settingsName : (sessionName ?? '');

    return Scaffold(
      appBar: AppBar(
        title: GradientText(
          eventName.isNotEmpty 
              ? '$eventName - Audience Dashboard'
              : 'Audience Dashboard', 
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
        ),
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
                const SizedBox(height: 32),
                const Text('Dedicate a Song', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
                const SizedBox(height: 8),
                const Text('Request a song and dedicate it to a friend (or challenge them to sing it!)', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 500,
                  child: SongLibrary(
                    actionLabel: 'Request',
                    onSongSelected: _requestSong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _requestSong(LibrarySong librarySong) {
    final requestedForController = TextEditingController();
    final dedicationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dedicate Song'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Requesting "${librarySong.title}"'),
              const SizedBox(height: 16),
              TextField(
                controller: requestedForController,
                decoration: const InputDecoration(labelText: 'Who should sing it?', hintText: 'e.g., John, The Host, or "Anyone"'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dedicationController,
                decoration: const InputDecoration(labelText: 'Dedication Message', hintText: 'e.g., Happy Birthday!'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final queueSong = Song(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: librarySong.title,
                  videoId: librarySong.videoId,
                  isLocal: librarySong.source == 'local',
                  requestedBy: 'audience',
                  requestedByName: 'Audience Member',
                  addedAt: DateTime.now(),
                  isRequest: true,
                  requestedFor: requestedForController.text.trim().isEmpty ? 'Anyone' : requestedForController.text.trim(),
                  dedication: dedicationController.text.trim().isEmpty ? null : dedicationController.text.trim(),
                );
                ref.read(sessionStateProvider.notifier).addToQueue(queueSong);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song request sent to Host!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
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
              nowPlaying.displaySingerName,
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
    return const ReactionPadCard(
      title: 'Audience Reactions',
      role: 'audience',
    );
  }
}
