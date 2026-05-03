import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/source_multi_select.dart';
import '../providers/library_provider.dart';
import '../providers/session_state_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/song.dart';
import '../models/library_song.dart';
import '../widgets/song_library.dart';
import '../widgets/reaction_pad.dart';

class SingerDashboard extends ConsumerStatefulWidget {
  const SingerDashboard({super.key});

  @override
  ConsumerState<SingerDashboard> createState() => _SingerDashboardState();
}

class _SingerDashboardState extends ConsumerState<SingerDashboard> {
  final TextEditingController _stageNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  LibrarySong? _selectedSong;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(appStateProvider).user;
      if (user != null && user.name.isNotEmpty) {
        _stageNameController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _stageNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _joinQueue() {
    if (_stageNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Stage Name.')));
      return;
    }
    if (_selectedSong == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a song from the library first.')));
      return;
    }

    final user = ref.read(appStateProvider).user;
    final queueSong = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _selectedSong!.title,
      videoId: _selectedSong!.videoId,
      isLocal: _selectedSong!.source == 'local',
      requestedBy: user?.id ?? 'unknown',
      requestedByName: _stageNameController.text.trim(),
      addedAt: DateTime.now(),
    );

    ref.read(sessionStateProvider.notifier).addToQueue(queueSong);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedSong!.title} added to queue!')));
    
    setState(() {
      _selectedSong = null;
    });
  }



  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            GradientText('Karaoke Night Live', style: TextStyle(fontSize: isDesktop ? 28 : 20, fontWeight: FontWeight.bold)),
            Text('Your ultimate karaoke party companion', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ]
        ),
        toolbarHeight: isDesktop ? 64 : 48,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSignUpCard(),
                const SizedBox(height: 8),
                SizedBox(height: 250, child: _buildLibraryCard()),
                const SizedBox(height: 8),
                const ReactionPadCard(title: 'Live Reactions', role: 'singer'),
                const SizedBox(height: 8),
                _buildAISuggestionsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpCard() {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sign Up to Sing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
          const SizedBox(height: 6),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: TextField(controller: _stageNameController, decoration: const InputDecoration(hintText: 'Stage Name', isDense: true))),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
                    child: Text(
                      _selectedSong?.title ?? 'Select a song below...',
                      style: TextStyle(color: _selectedSong == null ? AppTheme.textMuted : Colors.white, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _joinQueue,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  child: const Text('Join Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _stageNameController, decoration: const InputDecoration(hintText: 'Your Stage Name', isDense: true)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
                        child: Text(
                          _selectedSong?.title ?? 'Select a song below...',
                          style: TextStyle(color: _selectedSong == null ? AppTheme.textMuted : Colors.white, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _joinQueue,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard() {
    return SongLibrary(
      actionLabel: 'Sing',
      selectedSong: _selectedSong,
      onSongSelected: (song) {
        setState(() {
          _selectedSong = song;
        });
      },
    );
  }



  Widget _buildAISuggestionsCard() {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.accentPurpleLight, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Song Suggestions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isDesktop)
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "e.g., 'an 80s power ballad'",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  onPressed: () {},
                  child: const Text('Suggest', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "e.g., '80s rock'",
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  onPressed: () {},
                  child: const Text('Suggest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            )
        ],
      ),
    );
  }
}
