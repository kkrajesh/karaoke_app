import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_server_service.dart';
import '../providers/session_state_provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_emoji_overlay.dart';
import 'player_screen.dart';
import '../models/song.dart';

class PublicDisplayScreen extends ConsumerStatefulWidget {
  const PublicDisplayScreen({super.key});

  @override
  ConsumerState<PublicDisplayScreen> createState() => _PublicDisplayScreenState();
}

class _PublicDisplayScreenState extends ConsumerState<PublicDisplayScreen> {
  // For manual refresh button and transitions
  Key _playerKey = UniqueKey();
  String? _lastSongIdentity;

  void _manualRefresh() {
    print('[PublicDisplay] Executing instantaneous refresh sequence (UniqueKey Swap)...');
    setState(() {
      _playerKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);
    final nowPlaying = sessionState.nowPlaying;

    final currentIdentity = nowPlaying == null 
        ? "null" 
        : "${nowPlaying.videoId}_${nowPlaying.addedAt.millisecondsSinceEpoch}";

    // Synchronously ensure a full refresh if the song changes
    if (_lastSongIdentity != currentIdentity) {
      _lastSongIdentity = currentIdentity;
      _playerKey = UniqueKey();
      print('[PublicDisplay] Song changed to $currentIdentity. Generated new UniqueKey for PlayerScreen.');
    }

    final queue = sessionState.queue.where((s) => !s.isRequest).toList();
    final reactions = sessionState.reactions;

    final activePlayerKey = _playerKey;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Video Area (80% width)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Video Player or Intermission Graphic
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppTheme.accentPurple.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // 1. PlayerScreen wrapped with dynamic key for forced refresh
                            Positioned.fill(
                              child: PlayerScreen(
                                key: activePlayerKey,
                                song: nowPlaying,
                                isPublicDisplay: true,
                              ),
                            ),
                            // 2. Intermission overlay if no song is playing
                            if (nowPlaying == null)
                              Positioned.fill(
                                child: _buildIntermissionDisplay(),
                              ),
                            // 3. Emoji Counter overlay if song is playing
                            if (nowPlaying != null)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: _buildEmojiCounter(sessionState),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bottom Announcement Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accentPink.withOpacity(0.5), width: 2),
                      ),
                      child: _buildBottomAnnouncementBar(sessionState),
                    ),
                  ],
                ),
              ),
              
              // Sidebar (20% width)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Join Network / Scan QR
                      _buildJoinInfo(),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 16),
                      
                      // Now Playing Mini-Banner (if playing)
                      if (nowPlaying != null) ...[
                        const Text(
                          '🎤 NOW SINGING',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentPink, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentPurple, AppTheme.accentPink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentPink.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nowPlaying.displaySingerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(nowPlaying.title, style: const TextStyle(fontSize: 14, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 16),
                      ],
                      
                      // Up Next Queue
                      const Text(
                        '⏭️ UP NEXT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: queue.isEmpty
                            ? const Text('The stage is open! Request a song to jump in.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14))
                            : ListView.builder(
                                itemCount: queue.length > 5 ? 5 : queue.length, // Show up to 5
                                itemBuilder: (context, index) {
                                  final song = queue[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgInput,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppTheme.accentPurple.withOpacity(0.5),
                                          radius: 14,
                                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(song.displaySingerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                              Text(song.title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Emoji Animation Overlay
          const Positioned.fill(
            child: IgnorePointer(
              child: FloatingEmojiOverlay(),
            ),
          ),

          // Live Reactions Text Comments
          Positioned(
            bottom: 140, // Above the announcement bar
            left: 48,
            width: 400,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reactions.where((r) => r['isEmoji'] != true).toList().reversed.take(6).toList().reversed.map((r) {
                  final text = r['value'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, color: AppTheme.textMuted, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            text,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Controls Overlay
          Positioned(
            top: 40,
            left: 40,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 32),
                  onPressed: () {
                    ref.read(appStateProvider.notifier).clearRole();
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _manualRefresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntermissionDisplay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600 || constraints.maxHeight < 400;
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [AppTheme.bgCard, Colors.black],
              radius: 1.0,
            )
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_external_on, size: isCompact ? 60 : 120, color: AppTheme.textMuted),
                if (!isCompact) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Karaoke Night Live',
                    style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: AppTheme.accentPink),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get ready for the next performance!',
                    style: TextStyle(fontSize: 32, color: AppTheme.textMuted),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Get ready for the next performance!',
                    style: TextStyle(fontSize: 20, color: AppTheme.textMuted),
                  ),
                ]
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildJoinInfo() {
    final server = ref.watch(localServerProvider);
    final connectedHostIp = ref.watch(clientHostIpProvider);
    
    final serverIp = server.isRunning 
        ? server.ipAddress 
        : (connectedHostIp != null ? connectedHostIp : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JOIN THE PARTY',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Scan the QR code to request songs and send reactions!',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (serverIp != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: QrImageView(
                data: 'http://$serverIp:8080',
                version: QrVersions.auto,
                size: 150.0,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(8)),
            child: const Center(
              child: Icon(Icons.qr_code_2, size: 60, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildEmojiCounter(SessionState state) {
    int total = 0;
    int distinct = 0;
    state.emojiCounts.forEach((key, value) {
      total += value;
      distinct++;
    });

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentPink.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.accentPink.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: AppTheme.accentPink, size: 20),
          const SizedBox(width: 8),
          Text(
            '$total Reactions',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: AppTheme.border),
          const SizedBox(width: 8),
          Text(
            '$distinct types',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAnnouncementBar(SessionState state) {
    if (state.countdownEndTime != null) {
      return _CountdownDisplay(endTimeMs: state.countdownEndTime!, message: state.announcement);
    }
    
    if (state.announcement != null && state.announcement!.isNotEmpty) {
      return Center(
        child: Text(
          state.announcement!,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    // Default scrolling or static text
    return const Center(
      child: Text(
        'Welcome to Karaoke! Grab a drink, pick a song, and join the queue.',
        style: TextStyle(fontSize: 28, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _CountdownDisplay extends StatefulWidget {
  final int endTimeMs;
  final String? message;
  const _CountdownDisplay({required this.endTimeMs, this.message});

  @override
  State<_CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends State<_CountdownDisplay> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void didUpdateWidget(_CountdownDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTimeMs != widget.endTimeMs) {
      _updateTime();
    }
  }

  void _updateTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = widget.endTimeMs - now;
    setState(() {
      _remainingSeconds = diff > 0 ? (diff / 1000).ceil() : 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingSeconds <= 0) {
      return const Center(
        child: Text(
          "TIME'S UP! GET READY!",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
      );
    }

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.amber, size: 48),
          const SizedBox(width: 16),
          Text(
            timeString,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          const SizedBox(width: 24),
          Text(
            widget.message != null && widget.message!.isNotEmpty ? widget.message! : 'UNTIL SHOWTIME',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
