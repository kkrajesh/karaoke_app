import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vox_player_core/vox_player_core.dart';
import '../theme/app_theme.dart';
import '../models/library_song.dart';
import '../providers/library_provider.dart';
import '../providers/library_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    final searchProviders = ref.watch(voxSearchProvidersProvider);
    // The AiQueueService notification is handled globally or in AiQueueButton if we want. 
    // Here we just let AiQueueButton handle the UI.

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: UnifiedSearchUI(
        providers: searchProviders,
        actionBuilder: (context, result) {
          final isSelected = widget.selectedSong?.id == result.id;
          final isLocalDir = result.sourceType == 'LocalDirectory';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AiQueueButton(result: result, isVisible: true),
              ElevatedButton(
                onPressed: () {
                  final libSong = LibrarySong(
                    id: result.id,
                    title: result.title,
                    artist: result.artist,
                    videoId: result.url ?? result.id,
                    source: result.sourceType.toLowerCase(),
                    hasPreview: result.previewUrl != null,
                  );
                  widget.onSongSelected(libSong);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(50, 28),
                ),
                child: Text(isSelected ? 'Selected' : widget.actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          );
        },
      ),
    );
  }
}
