import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../providers/settings_provider.dart';

class HostDashboard extends ConsumerStatefulWidget {
  const HostDashboard({super.key});

  @override
  ConsumerState<HostDashboard> createState() => _HostDashboardState();
}

class _HostDashboardState extends ConsumerState<HostDashboard> {
  int _lastQueueLength = 0;
  int _lastRequestLength = 0;

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
                Expanded(flex: 7, child: _buildLeftColumn()),
                Expanded(flex: 5, child: _buildRightColumn()),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildLeftColumn(isMobile: true),
                  _buildRightColumn(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLeftColumn({bool isMobile = false}) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nowPlaying != null ? 'Now Playing: ${nowPlaying.requestedByName} - ${nowPlaying.title}' : 'Now Playing: Nobody', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
          const SizedBox(height: 12),
          if (nowPlaying != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                ),
                clipBehavior: Clip.antiAlias,
                child: PlayerScreen(song: nowPlaying),
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
          const SizedBox(height: 32),
          
          // 2-Column layout for AI Host Info and Reactions
          if (isMobile) ...[
            _buildAiHostInfo(),
            const SizedBox(height: 16),
            _buildReactionsBoard(),
          ] else 
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAiHostInfo()),
                const SizedBox(width: 16),
                Expanded(child: _buildReactionsBoard()),
              ],
            ),
            
          const SizedBox(height: 16),
          
          if (nowPlaying != null)
            Container(
              decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
              child: ExpansionTile(
                title: const Text('Debug Metadata', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${nowPlaying.id}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text('Type: ${nowPlaying.isLocal ? "Local File" : "YouTube Video"}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text('Source/Path: ${nowPlaying.videoId}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        if (nowPlaying.isLocal)
                          Text('Resolved File URL: file:///${nowPlaying.videoId.replaceAll('\\\\', '/')}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
          const SizedBox(height: 32),
          
          _buildDisplayControls(),
          
          const SizedBox(height: 32),
          
          // Collapsible Manage Library
          Container(
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
            child: ExpansionTile(
              title: const Text('Manage Library & Import', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
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
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Settings
          Container(
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
            child: ExpansionTile(
              title: const Text('App Settings & Integrations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final settings = ref.watch(settingsProvider);
                      final eventNameCtrl = TextEditingController(text: settings.eventName);
                      final webhookCtrl = TextEditingController(text: settings.googleSheetsWebhookUrl);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: eventNameCtrl,
                            decoration: const InputDecoration(hintText: 'e.g. Friday Night Karaoke'),
                            onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(eventName: val),
                          ),
                          const SizedBox(height: 16),
                          const Text('Google Sheets Webhook URL', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: webhookCtrl,
                            decoration: const InputDecoration(hintText: 'https://script.google.com/...'),
                            onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(googleSheetsWebhookUrl: val),
                          ),
                          const SizedBox(height: 8),
                          const Text('Used for automated performance logging.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayControls() {
    final announcementController = TextEditingController();
    
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: const Text('Display Controls & Announcements', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Public Display Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: announcementController,
                        decoration: const InputDecoration(hintText: 'Custom message to display...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (announcementController.text.isNotEmpty) {
                          ref.read(sessionStateProvider.notifier).pushAnnouncement(announcementController.text.trim());
                          announcementController.clear();
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.timer),
                      label: const Text('5 Min'),
                      onPressed: () => ref.read(sessionStateProvider.notifier).pushCountdown(300),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.timer),
                      label: const Text('15 Min'),
                      onPressed: () => ref.read(sessionStateProvider.notifier).pushCountdown(900),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2)),
                      onPressed: () => ref.read(sessionStateProvider.notifier).pushCountdown(null),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiHostInfo() {
    final sessionState = ref.watch(sessionStateProvider);
    final funFact = sessionState.funFact;
    
    if (funFact == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Host Teleprompter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentPurpleLight,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            funFact,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsBoard() {
    final reactions = ref.watch(sessionStateProvider).reactions;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_emotions, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Live Reactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reactions.isEmpty && ref.watch(sessionStateProvider).emojiCounts.isEmpty)
            const Text('No reactions yet.', style: TextStyle(color: AppTheme.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...ref.watch(sessionStateProvider).emojiCounts.entries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.accentPurple)),
                  child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                )),
                ...reactions.where((r) => r['isEmoji'] != true).toList().reversed.take(15).map((r) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(r['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                )),
              ],
            ),
        ],
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

  Widget _buildRightColumn() {
    final fullQueue = ref.watch(queueProvider);
    final queue = fullQueue.where((s) => !s.isRequest).toList();
    final requests = fullQueue.where((s) => s.isRequest).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24, right: 24, bottom: 24, left: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Singer Queue (${queue.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
          const SizedBox(height: 12),
          
          if (queue.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
              child: const Text('The queue is empty!', style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final song = queue[index];
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
                },
              ),
            ),
            
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: queue.isEmpty ? null : () {
                ref.read(sessionStateProvider.notifier).playNext();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)), // Green-800
              child: const Text('Start Next Singer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 32),
          Text('Song Requests (${requests.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
              child: const Text('No pending requests.', style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
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
                          if (index < requests.length - 1)
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
                },
              ),
            ),
          
          const SizedBox(height: 32),
          SizedBox(
            height: 400,
            child: SongLibrary(
              actionLabel: 'Add to Queue',
              onSongSelected: _addSongToQueue,
            ),
          ),
        ],
      ),
    );
  }
}

