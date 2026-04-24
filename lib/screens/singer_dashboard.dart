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
import 'player_screen.dart';

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

  void _previewSong(String videoId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          contentPadding: EdgeInsets.zero,
          content: AspectRatio(
            aspectRatio: 16 / 9,
            child: PlayerScreen(videoId: videoId),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.accentPurpleLight)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            GradientText('Karaoke Night Live', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Your ultimate karaoke party companion', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ]
        ),
        toolbarHeight: 64,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSignUpCard(),
                const SizedBox(height: 12),
                Expanded(child: _buildLibraryCard()),
                const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sign Up to Sing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
          const SizedBox(height: 12),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: TextField(controller: _stageNameController, decoration: const InputDecoration(hintText: 'Your Stage Name'))),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
                    child: Text(
                      _selectedSong?.title ?? 'Select a song below...',
                      style: TextStyle(color: _selectedSong == null ? AppTheme.textMuted : Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _joinQueue,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)), // Green-800
                  child: const Text('Join Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _stageNameController, decoration: const InputDecoration(hintText: 'Your Stage Name')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
                  child: Text(
                    _selectedSong?.title ?? 'Select a song below...',
                    style: TextStyle(color: _selectedSong == null ? AppTheme.textMuted : Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _joinQueue,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), padding: const EdgeInsets.symmetric(vertical: 16)), // Green-800
                  child: const Text('Join Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard() {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final asyncSongs = ref.watch(filteredLibraryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Song Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
                Row(
                  children: [
                    const SourceMultiSelect(),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 250, 
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => ref.read(searchQueryProvider.notifier).updateQuery(val),
                        decoration: const InputDecoration(hintText: 'Search songs or artists...', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Song Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => ref.read(searchQueryProvider.notifier).updateQuery(val),
                  decoration: const InputDecoration(hintText: 'Search songs or artists...'),
                ),
              ],
            ),
          const SizedBox(height: 12),
          
          Expanded(
            child: asyncSongs.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return const Center(
                    child: Text('No songs found matching your search.', style: TextStyle(color: AppTheme.textMuted)),
                  );
                }
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) => _buildSongItem(songs[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
              error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(LibrarySong song) {
    IconData? icon;
    Color iconColor = Colors.white;
    String? customIconText;

    if (song.source == 'youtube') {
      icon = Icons.smart_display;
      iconColor = Colors.red;
    } else if (song.source == 'local') {
      icon = Icons.music_note;
      iconColor = Colors.blue;
    } else if (song.source == 'smule') {
      customIconText = 'S';
      iconColor = Colors.green;
    }

    final isSelected = _selectedSong?.id == song.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentPurple.withOpacity(0.2) : AppTheme.bgInput,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: AppTheme.accentPurple) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(song.artist, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 0; i < 5; i++)
                      Icon(Icons.star, size: 16, color: i < song.rating ? Colors.amber : AppTheme.border),
                    if (song.hasPreview) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _previewSong(song.videoId),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Preview', style: TextStyle(fontSize: 10)),
                        ),
                      )
                    ]
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (icon != null)
                Icon(icon, color: iconColor, size: 20)
              else if (customIconText != null)
                Text(customIconText, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 16)),
              
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedSong = song;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                child: Text(isSelected ? 'Selected' : 'Sing', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAISuggestionsCard() {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.accentPurpleLight),
              SizedBox(width: 8),
              Text(
                'AI Song Suggestions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
             Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: "e.g., 'an 80s power ballad'",
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () {},
                  child: const Text('Suggest', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
        ],
      ),
    );
  }
}
