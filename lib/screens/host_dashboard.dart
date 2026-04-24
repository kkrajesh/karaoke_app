import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_screen.dart';
import '../services/local_server_service.dart';
import '../providers/session_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';

class HostDashboard extends ConsumerStatefulWidget {
  const HostDashboard({super.key});

  @override
  ConsumerState<HostDashboard> createState() => _HostDashboardState();
}

class _HostDashboardState extends ConsumerState<HostDashboard> {
  bool _isServerRunning = false;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    final server = ref.read(localServerProvider);
    await server.startServer();
    if (mounted) {
      setState(() {
        _isServerRunning = true;
      });
    }
  }

  @override
  void dispose() {
    ref.read(localServerProvider).stopServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.read(localServerProvider);

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
                  color: _isServerRunning ? AppTheme.accentPurple.withOpacity(0.2) : AppTheme.bgInput,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isServerRunning ? AppTheme.accentPurple : AppTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isServerRunning ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: _isServerRunning ? AppTheme.accentPurpleLight : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isServerRunning 
                        ? 'Connect Singers to: ${server.ipAddress}:8080'
                        : 'Starting server...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: _isServerRunning ? AppTheme.accentPurpleLight : AppTheme.textMuted,
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
                child: PlayerScreen(videoId: nowPlaying.videoId, key: ValueKey(nowPlaying.id)),
              ),
            )
          else
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
          const Text('Song Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No requests yet.', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    final queue = ref.watch(queueProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24, right: 24, bottom: 24, left: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Singer Queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
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
              constraints: const BoxConstraints(maxHeight: 400),
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
          const Text('Manage Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPink)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
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
          
          const SizedBox(height: 32),
          const Row(
            children: [
              Icon(Icons.smart_display, color: AppTheme.accentPink, size: 20),
              SizedBox(width: 8),
              Text('Find on YouTube', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Expanded(child: TextField(decoration: InputDecoration(hintText: "e.g., 'Queen Bohemian Rhapsody karaoke'"))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink), child: const Text('Search')),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('Audience Reactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }
}

