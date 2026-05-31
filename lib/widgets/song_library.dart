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
  final bool showFilters;
  final bool hideSmule;

  const SongLibrary({
    super.key,
    required this.actionLabel,
    required this.onSongSelected,
    this.selectedSong,
    this.showFilters = true,
    this.hideSmule = false,
  });

  @override
  ConsumerState<SongLibrary> createState() => _SongLibraryState();
}

class _SongLibraryState extends ConsumerState<SongLibrary> {
  void _openFullScreenSearch(BuildContext context, List<VoxSearchProvider> providers) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgCard,
            title: const Text('Song Library Search'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: UnifiedSearchUI(
            providers: providers,
            defaultFilterKaraoke: true,
            showFilters: widget.showFilters,
            actionBuilder: (ctx, result) {
              final isSelected = widget.selectedSong?.id == result.id;
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
                      Navigator.of(context).pop();
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchProviders = ref.watch(voxSearchProvidersProvider);
    final providers = widget.hideSmule 
        ? searchProviders.where((p) => p.providerId != 'smule').toList() 
        : searchProviders;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0), // give room for the button
            child: UnifiedSearchUI(
              providers: providers,
              defaultFilterKaraoke: true,
              showFilters: widget.showFilters,
              actionBuilder: (context, result) {
                final isSelected = widget.selectedSong?.id == result.id;
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
          ),
          Positioned(
            top: 4,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white70),
              tooltip: 'Full Screen Search',
              onPressed: () => _openFullScreenSearch(context, providers),
            ),
          ),
        ],
      ),
    );
  }
}
