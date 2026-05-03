import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'player_screen.dart';
import '../services/local_server_service.dart';
import '../providers/session_state_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/song.dart';
import '../models/library_song.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/song_library.dart';
import '../widgets/reaction_pad.dart';

class HostDashboard extends ConsumerStatefulWidget {
  const HostDashboard({super.key});

  @override
  ConsumerState<HostDashboard> createState() => _HostDashboardState();
}

class _HostDashboardState extends ConsumerState<HostDashboard> {
  int _lastQueueLength = 0;
  int _lastRequestLength = 0;

  final TextEditingController _announcementController = TextEditingController();

  @override
  void dispose() {
    _announcementController.dispose();
    super.dispose();
  }

  void _showFullscreenDialog(String title, Widget Function(BuildContext context, WidgetRef ref) contentBuilder) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(24),
            child: Consumer(
              builder: (context, ref, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Expanded(child: contentBuilder(context, ref)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Widget Function(BuildContext context, WidgetRef ref) contentBuilder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
        IconButton(
          icon: const Icon(Icons.fullscreen, color: Colors.white70),
          tooltip: 'Expand $title',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _showFullscreenDialog(title, contentBuilder),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for queue changes to show notification bubbles
    ref.listen(sessionStateProvider, (previous, next) {
      if (previous == null) return;
      
      final activeQueueLength = next.queue.where((s) => !s.isRequest).length;
      final requestLength = next.queue.where((s) => s.isRequest).length;
      
      if (activeQueueLength > _lastQueueLength) {
        final newSong = next.queue.where((s) => !s.isRequest).last;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎤 New Singer Added: ${newSong.requestedByName}'),
          backgroundColor: AppTheme.accentPink,
          duration: const Duration(seconds: 2),
        ));
      }
      if (requestLength > _lastRequestLength) {
        final newReq = next.queue.where((s) => s.isRequest).last;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📬 New Request from ${newReq.requestedByName}'),
          backgroundColor: AppTheme.accentBlue,
          duration: const Duration(seconds: 2),
        ));
      }
      
      _lastQueueLength = activeQueueLength;
      _lastRequestLength = requestLength;
    });

    final server = ref.watch(localServerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            GradientText('Karaoke Night Live', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Your ultimate karaoke party companion', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ]
        ),
        toolbarHeight: 80,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: server.isRunning ? AppTheme.accentPurple.withOpacity(0.2) : AppTheme.bgInput,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: server.isRunning ? AppTheme.accentPurple : AppTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      server.isRunning ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: server.isRunning ? AppTheme.accentPurpleLight : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      server.isRunning 
                        ? 'Connect Singers to: ${server.ipAddress}:8080'
                        : 'Server is offline. Start it on the Home Screen.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: server.isRunning ? AppTheme.accentPurpleLight : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildPlayerColumn()),
                Expanded(flex: 4, child: _buildQueueColumn()),
                Expanded(flex: 4, child: _buildLibraryColumn()),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildPlayerColumn(isMobile: true),
                  _buildQueueColumn(isMobile: true),
                  _buildLibraryColumn(isMobile: true),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPlayerColumn({bool isMobile = false}) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nowPlaying != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: PlayerScreen(song: nowPlaying),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildReactionsOverlay(),
                  ),
                ],
              ),
            ),
          if (nowPlaying == null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(child: Text('Waiting for next singer...', style: TextStyle(color: AppTheme.textMuted))),
              ),
            ),
          const SizedBox(height: 16),
          
          _buildAiHostInfo(),
          
          const SizedBox(height: 16),
          const ReactionPadCard(title: 'Live Reactions Pad', role: 'host'),
          const SizedBox(height: 16),
          
          if (nowPlaying != null)
            _buildDebugMetadata(nowPlaying),
        ],
      ),
    ),
  );
}

  Widget _buildReactionsOverlay() {
    final emojiCounts = ref.watch(sessionStateProvider).emojiCounts;
    final textReactions = ref.watch(sessionStateProvider).reactions.where((r) => r['isEmoji'] != true).toList().reversed.take(5).toList().reversed.toList();

    if (emojiCounts.isEmpty && textReactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (textReactions.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(textReactions.length, (index) {
              final isLast = index == textReactions.length - 1;
              final r = textReactions[index];
              return Align(
                widthFactor: isLast ? 1.0 : 0.6, // Overlap the next one by 40%
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 0.5),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))],
                  ),
                  child: Text(r['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              );
            }),
          ),
        if (textReactions.isNotEmpty && emojiCounts.isNotEmpty)
          const SizedBox(height: 8),
        if (emojiCounts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: emojiCounts.entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5)),
              ),
              child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildAiHostInfoContent(WidgetRef ref) {
    final funFact = ref.watch(sessionStateProvider).funFact;
    if (funFact == null) return const Center(child: Text('No teleprompter info available.'));
    return SingleChildScrollView(
      child: Text(
        funFact,
        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
      ),
    );
  }

  Widget _buildAiHostInfo() {
    final funFact = ref.watch(sessionStateProvider).funFact;
    if (funFact == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Host Teleprompter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentPurpleLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showFullscreenDialog('Host Teleprompter', (c, r) => _buildAiHostInfoContent(r)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            funFact,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDebugMetadataContent(WidgetRef ref, Song nowPlaying) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ID: ${nowPlaying.id}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Type: ${nowPlaying.isLocal ? "Local File" : "YouTube Video"}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            final url = nowPlaying.isLocal 
                ? 'file:///${nowPlaying.videoId.replaceAll('\\\\', '/')}' 
                : 'https://www.youtube.com/watch?v=${nowPlaying.videoId}';
            launchUrl(Uri.parse(url));
          },
          child: Text(
            nowPlaying.isLocal 
              ? 'Source/Path: ${nowPlaying.videoId}' 
              : 'YouTube URL: https://www.youtube.com/watch?v=${nowPlaying.videoId}', 
            style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline, fontSize: 16)
          ),
        ),
        if (nowPlaying.isLocal)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Resolved File URL: file:///${nowPlaying.videoId.replaceAll('\\\\', '/')}', style: const TextStyle(color: Colors.amberAccent, fontSize: 16)),
          ),
      ],
    );
  }

  Widget _buildDebugMetadata(Song nowPlaying) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Debug Metadata', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showFullscreenDialog('Debug Metadata', (c, r) => _buildDebugMetadataContent(r, nowPlaying)),
            )
          ]
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: _buildDebugMetadataContent(ref, nowPlaying),
          )
        ],
      ),
    );
  }

  Widget _buildQueueContent(WidgetRef ref, {bool isExpanded = false}) {
    final queue = ref.watch(queueProvider).where((s) => !s.isRequest).toList();
    
    if (queue.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
        child: const Text('The queue is empty!', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ListView.builder(
        shrinkWrap: !isExpanded,
        itemCount: queue.length,
        itemBuilder: (context, index) => _buildQueueItem(queue[index], index),
      ),
    );
  }

  Widget _buildRequestsContent(WidgetRef ref, {bool isExpanded = false}) {
    final requests = ref.watch(queueProvider).where((s) => s.isRequest).toList();
    
    if (requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
        child: const Text('No pending requests.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ListView.builder(
        shrinkWrap: !isExpanded,
        itemCount: requests.length,
        itemBuilder: (context, index) => _buildRequestItem(requests[index], index, requests.length),
      ),
    );
  }

  Widget _buildQueueColumn({bool isMobile = false}) {
    final queueLength = ref.watch(queueProvider).where((s) => !s.isRequest).length;
    final requestsLength = ref.watch(queueProvider).where((s) => s.isRequest).length;
    
    return Container(
      padding: const EdgeInsets.only(top: 16, right: 8, bottom: 16, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Singer Queue ($queueLength)', (c, r) => _buildQueueContent(r, isExpanded: true)),
          const SizedBox(height: 8),
          
          isMobile 
            ? Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: _buildQueueContent(ref),
              )
            : Expanded(child: _buildQueueContent(ref, isExpanded: true)),
            
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: queueLength == 0 ? null : () {
                ref.read(sessionStateProvider.notifier).playNext();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
              child: const Text('Start Next Singer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Song Requests ($requestsLength)', (c, r) => _buildRequestsContent(r, isExpanded: true)),
          const SizedBox(height: 8),
          
          isMobile
            ? Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: _buildRequestsContent(ref),
              )
            : Expanded(child: _buildRequestsContent(ref, isExpanded: true)),
        ],
      ),
    );
  }

  Widget _buildLibraryColumn({bool isMobile = false}) {
    return Container(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Song Library', (c, r) => SongLibrary(actionLabel: 'Add to Queue', onSongSelected: _addSongToQueue)),
          const SizedBox(height: 8),
          isMobile
            ? SizedBox(
                height: 400,
                child: SongLibrary(actionLabel: 'Add to Queue', onSongSelected: _addSongToQueue),
              )
            : Expanded(
                child: Container(
                  decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
                  child: SongLibrary(actionLabel: 'Add to Queue', onSongSelected: _addSongToQueue),
                ),
              ),
          const SizedBox(height: 16),
          _buildDisplayControls(),
          const SizedBox(height: 12),
          _buildManageLibraryTile(),
          const SizedBox(height: 12),
          _buildAppSettingsTile(),
        ],
      ),
    );
  }

  Widget _buildQueueItem(Song song, int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.accentPurple,
        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(song.requestedByName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(song.title, style: const TextStyle(color: AppTheme.textMuted)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () {
          ref.read(sessionStateProvider.notifier).removeFromQueue(song.id);
        },
      ),
    );
  }

  Widget _buildRequestItem(Song req, int index, int totalRequests) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentBlue,
          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(req.requestedFor ?? 'Anyone', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(req.title, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text('Requested by: ${req.requestedByName}', style: const TextStyle(fontSize: 12)),
            if (req.dedication != null && req.dedication!.isNotEmpty)
              Text('"${req.dedication}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.amber, fontSize: 12)),
            if (req.hostNote != null && req.hostNote!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                child: Text('Note: ${req.hostNote}', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20, color: Colors.white70),
                onPressed: () => ref.read(sessionStateProvider.notifier).nudgeRequest(req.id, -1),
              ),
            if (index < totalRequests - 1)
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.white70),
                onPressed: () => ref.read(sessionStateProvider.notifier).nudgeRequest(req.id, 1),
              ),
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.white),
              onPressed: () => _editRequestNote(req),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _approveRequestWithSinger(req),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => ref.read(sessionStateProvider.notifier).removeFromQueue(req.id),
            ),
          ],
        ),
      ),
    );
  }

  void _approveRequestWithSinger(Song req) {
    final hostNameController = TextEditingController();
    if (req.requestedFor != null && req.requestedFor != 'Anyone') {
      hostNameController.text = req.requestedFor!;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Assign singer for "${req.title}"'),
              const SizedBox(height: 16),
              TextField(
                controller: hostNameController,
                decoration: const InputDecoration(labelText: 'Assigned Singer'),
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
                final assignedName = hostNameController.text.trim();
                ref.read(sessionStateProvider.notifier).approveRequest(
                  req.id, 
                  assignedSinger: assignedName.isEmpty ? null : assignedName
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  void _editRequestNote(Song req) {
    final noteController = TextEditingController(text: req.hostNote ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Note to Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Note for "${req.title}"'),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Internal Note'),
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
                ref.read(sessionStateProvider.notifier).updateRequestNote(req.id, noteController.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addSongToQueue(LibrarySong librarySong) {
    final hostNameController = TextEditingController();
    final hostUser = ref.read(appStateProvider).user;
    if (hostUser != null) {
      hostNameController.text = hostUser.name;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Queue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add "${librarySong.title}" to the queue?'),
              const SizedBox(height: 16),
              TextField(
                controller: hostNameController,
                decoration: const InputDecoration(labelText: 'Singer Name'),
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
                  requestedBy: hostUser?.id ?? 'host',
                  requestedByName: hostNameController.text.trim().isEmpty ? 'Host' : hostNameController.text.trim(),
                  addedAt: DateTime.now(),
                );
                ref.read(sessionStateProvider.notifier).addToQueue(queueSong);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDisplayControlsContent(WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Public Display Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _announcementController,
                  decoration: const InputDecoration(hintText: 'Custom message to display...'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_announcementController.text.isNotEmpty) {
                    ref.read(sessionStateProvider.notifier).pushAnnouncement(_announcementController.text.trim());
                    _announcementController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                child: const Text('Push'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(sessionStateProvider.notifier).pushAnnouncement(null);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2)),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('Please request songs!'), onPressed: () => ref.read(sessionStateProvider.notifier).pushAnnouncement('Please join the Wi-Fi to request songs!')),
              ActionChip(label: const Text('Food & Drinks'), onPressed: () => ref.read(sessionStateProvider.notifier).pushAnnouncement('Food and drinks are available at the bar!')),
              ActionChip(label: const Text('Last Call'), onPressed: () => ref.read(sessionStateProvider.notifier).pushAnnouncement('Last call for song requests!')),
            ],
          ),
          const Divider(color: AppTheme.border, height: 32),
          const Text('Countdown Timer', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.timer, size: 16),
                label: const Text('5 Min'),
                onPressed: () => ref.read(sessionStateProvider.notifier).pushCountdown(300),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.timer, size: 16),
                label: const Text('15 Min'),
                onPressed: () => ref.read(sessionStateProvider.notifier).pushCountdown(900),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop, size: 16),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2)),
                onPressed: () => ref.read(sessionStateProvider.notifier).pushCountdown(null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayControls() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Display Controls & Announcements', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showFullscreenDialog('Display Controls', (c, r) => _buildDisplayControlsContent(r)),
            )
          ]
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildDisplayControlsContent(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildManageLibraryContent(WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue), child: const Text('Add From Folder'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.border), child: const Text('View & Edit All'))),
            ],
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Use "Artist - Title.ext" format for best results.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10))),
          const Divider(color: AppTheme.border, height: 32),
          
          const Text('Add Online Song Manually', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'Song Title')),
          const SizedBox(height: 8),
          const TextField(decoration: InputDecoration(hintText: 'Artist')),
          const SizedBox(height: 8),
          const TextField(decoration: InputDecoration(hintText: 'YouTube or Smule URL')),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () {}, child: const Text('Add to Library')),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storage, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('Import MediaMonkey Database', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Directly upload your MediaMonkey database file (MM.DB). Usually located in AppData/Roaming/MediaMonkey.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]), child: const Text('Upload MM.DB File')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageLibraryTile() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Manage Library & Import', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showFullscreenDialog('Manage Library', (c, r) => _buildManageLibraryContent(r)),
            )
          ]
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildManageLibraryContent(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsContent(WidgetRef ref) {
    // This assumes we instantiate a local controller in the closure just for rendering,
    // which is fine for the app settings since we use onChanged to dispatch.
    final settings = ref.watch(settingsProvider);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: settings.eventName,
            decoration: const InputDecoration(hintText: 'e.g. Friday Night Karaoke'),
            onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(eventName: val),
          ),
          const SizedBox(height: 16),
          const Text('Google Sheets Webhook URL', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: settings.googleSheetsWebhookUrl,
            decoration: const InputDecoration(hintText: 'https://script.google.com/...'),
            onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(googleSheetsWebhookUrl: val),
          ),
          const SizedBox(height: 8),
          const Text('Used for automated performance logging.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAppSettingsTile() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('App Settings & Integrations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showFullscreenDialog('App Settings', (c, r) => _buildAppSettingsContent(r)),
            )
          ]
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildAppSettingsContent(ref),
          ),
        ],
      ),
    );
  }
}
