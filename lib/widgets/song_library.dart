import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../models/library_song.dart';
import '../providers/library_provider.dart';
import '../widgets/source_multi_select.dart';
import '../screens/player_screen.dart';

class SongLibrary extends ConsumerStatefulWidget {
  final String actionLabel;
  final Function(LibrarySong) onSongSelected;
  final LibrarySong? selectedSong;

  const SongLibrary({
    super.key,
    required this.actionLabel,
    required this.onSongSelected,
    this.selectedSong,
  });

  @override
  ConsumerState<SongLibrary> createState() => _SongLibraryState();
}

class _SongLibraryState extends ConsumerState<SongLibrary> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _previewSong(LibrarySong librarySong) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          contentPadding: EdgeInsets.zero,
          content: AspectRatio(
            aspectRatio: 16 / 9,
            child: PlayerScreen(
              song: Song(
                id: 'preview',
                videoId: librarySong.videoId,
                title: librarySong.title,
                isLocal: librarySong.source == 'local',
                requestedBy: 'preview',
                requestedByName: 'preview',
                addedAt: DateTime.now(),
              ),
            ),
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
    final asyncSongs = ref.watch(filteredLibraryProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Text('Song Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
              const SourceMultiSelect(),
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
          const SizedBox(height: 8),
          
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

    final isSelected = widget.selectedSong?.id == song.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(song.artist, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    for (int i = 0; i < 5; i++)
                      Icon(Icons.star, size: 10, color: i < song.rating ? Colors.amber : AppTheme.border),
                    if (song.hasPreview) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _previewSong(song),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Preview', style: TextStyle(fontSize: 9)),
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
              
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => widget.onSongSelected(song),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(50, 28),
                ),
                child: Text(isSelected ? 'Selected' : widget.actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
