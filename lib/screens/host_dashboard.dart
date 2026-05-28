import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'player_screen.dart';
import '../services/local_server_service.dart';
import '../providers/session_state_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/song.dart';
import '../models/library_song.dart';
import '../models/app_user.dart';
import '../providers/settings_provider.dart';
import '../providers/host_security_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/song_library.dart';
import '../widgets/reaction_pad.dart';
import 'singer_dashboard.dart';
import 'audience_dashboard.dart';
import 'public_display_screen.dart';
import 'ai_prompts_config_widget.dart';

class HostDashboard extends ConsumerStatefulWidget {
  const HostDashboard({super.key});

  @override
  ConsumerState<HostDashboard> createState() => _HostDashboardState();
}

class _HostDashboardState extends ConsumerState<HostDashboard> {
  int _lastQueueLength = 0;
  int _lastRequestLength = 0;

  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _timerMessageController = TextEditingController(text: 'Starting shortly!');

  @override
  void dispose() {
    _announcementController.dispose();
    _timerMessageController.dispose();
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

  Widget _buildSectionHeader(String title, Widget Function(BuildContext context, WidgetRef ref) contentBuilder, {List<Widget>? actions}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentPink), overflow: TextOverflow.ellipsis)),
        if (actions != null) ...actions,
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

  void _showDashboardModal(Widget dashboard) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: Stack(
            children: [
              dashboard,
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton.extended(
                  backgroundColor: AppTheme.accentPink,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('Return to Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchDashboardInBrowser(String role) async {
    final server = ref.read(localServerProvider);
    if (!server.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please start the server first.')));
      return;
    }
    final url = Uri.parse('http://${server.ipAddress}:8080/?role=$role');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showPopup(String title, Widget Function(BuildContext) contentBuilder) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 900,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Builder(builder: contentBuilder),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsPopup(WidgetRef ref, {int initialIndex = 0}) {
    final isPrimaryHost = ref.read(appStateProvider).isPrimaryHost;
    _showPopup('Host Settings', (dialogContext) {
      return DefaultTabController(
        initialIndex: initialIndex,
        length: isPrimaryHost ? 4 : 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                if (isPrimaryHost) const Tab(text: 'Network Config'),
                const Tab(text: 'Manage Library'),
                const Tab(text: 'App Settings'),
                const Tab(text: 'AI Prompts'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: AppTheme.accentPink,
              dividerColor: AppTheme.border,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  if (isPrimaryHost) _buildNetworkConfigContent(ref),
                  _buildManageLibraryContent(ref),
                  _buildAppSettingsContent(ref),
                  const SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16.0), child: AiPromptsConfigWidget())),
                ],
              ),
            ),
          ],
        ),
      );
    });
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
          content: Text('🎤 New Singer Added: ${newSong.displaySingerName}'),
          backgroundColor: AppTheme.accentPink,
          duration: const Duration(seconds: 2),
        ));
      }
      if (requestLength > _lastRequestLength) {
        final newReq = next.queue.where((s) => s.isRequest).last;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📬 New Request from ${newReq.displaySingerName}'),
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
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = MediaQuery.of(context).size.width > 800;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientText(
                  ref.watch(settingsProvider).eventName.isNotEmpty 
                      ? '${ref.watch(settingsProvider).eventName} - Host Dashboard'
                      : 'Host Dashboard', 
                  style: TextStyle(fontSize: isDesktop ? 28 : 20, fontWeight: FontWeight.bold)
                ),
                if (isDesktop)
                  const Text('Your ultimate karaoke party companion', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ]
            );
          }
        ),
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement, color: Colors.orangeAccent),
            tooltip: 'Display Controls & Announcements',
            onPressed: () => _showPopup('Display Controls & Announcements', (dialogContext) => _buildDisplayControlsContent(ref)),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.greenAccent),
            tooltip: 'Search & Add Songs',
            onPressed: () => _showPopup('Song Library', (dialogContext) => SongLibrary(
              actionLabel: 'Add to Queue', 
              onSongSelected: (song) {
                 Navigator.pop(dialogContext);
                 _addSongToQueue(song);
              },
              showFilters: false,
              hideSmule: true,
            )),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Host Settings',
            onPressed: () => _showSettingsPopup(ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.flip_to_front, color: AppTheme.accentBlue),
            tooltip: 'Dashboards',
            onSelected: (value) {
              if (value.startsWith('peek_')) {
                final role = value.split('_')[1];
                if (role == 'singer') _showDashboardModal(const SingerDashboard());
                if (role == 'audience') _showDashboardModal(const AudienceDashboard());
                if (role == 'display') _showDashboardModal(const PublicDisplayScreen());
              } else if (value.startsWith('pop_')) {
                final role = value.split('_')[1];
                _launchDashboardInBrowser(role);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'peek_singer',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Singer Dashboard'),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18, color: AppTheme.textMuted),
                      tooltip: 'Open in separate window',
                      onPressed: () {
                        Navigator.pop(context);
                        _launchDashboardInBrowser('singer');
                      },
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'peek_audience',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Audience Dashboard'),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18, color: AppTheme.textMuted),
                      tooltip: 'Open in separate window',
                      onPressed: () {
                        Navigator.pop(context);
                        _launchDashboardInBrowser('audience');
                      },
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'peek_display',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Public Display'),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18, color: AppTheme.textMuted),
                      tooltip: 'Open in separate window',
                      onPressed: () {
                        Navigator.pop(context);
                        _launchDashboardInBrowser('display');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: InteractiveHoverMenu(
              width: 420,
              menuWidget: _buildServerStatusCard(server, context, bottomAction: null),
              child: InkWell(
                onTap: () => _showSettingsPopup(ref, initialIndex: 0),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Icon(
                    server.isRunning ? Icons.wifi : Icons.wifi_off,
                    size: 24,
                    color: server.isRunning ? AppTheme.accentPurpleLight : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildPlayerColumn()),
                Expanded(flex: 1, child: _buildQueueColumn()),
              ],
            );
          } else if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildPlayerColumn(isMobile: true)),
                Expanded(flex: 1, child: _buildQueueColumn(isMobile: true)),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildPlayerColumn(isMobile: true),
                  _buildQueueColumn(isMobile: true),
                ],
              ),
            );
          }
        },
      ),
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
          if (nowPlaying != null) ...[
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
            const SizedBox(height: 8),
            _buildReactionsOverlay(),
          ],
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
          
          const ReactionPadCard(title: 'Live Reactions Pad', role: 'host'),
          const SizedBox(height: 16),
          
          _buildAiHostInfo(),
          
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
      child: MarkdownBody(
        data: funFact,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
          h3: const TextStyle(color: AppTheme.accentPurpleLight, fontWeight: FontWeight.bold, fontSize: 22),
          tableHead: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPink, fontSize: 16),
          tableBody: const TextStyle(color: Colors.white70, fontSize: 16),
          tableBorder: TableBorder.all(color: AppTheme.border),
          listBullet: const TextStyle(fontSize: 16, color: Colors.white),
        ),
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
          const SizedBox(height: 8),
          if (funFact.isNotEmpty)
            MarkdownBody(
              data: funFact,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 12, height: 1.3, color: Colors.white),
                h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight),
                tableBody: const TextStyle(fontSize: 12, color: Colors.white70),
                tableHead: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentPink),
                tableBorder: TableBorder.all(color: AppTheme.border),
                listBullet: const TextStyle(fontSize: 12, color: Colors.white),
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
        addSemanticIndexes: false,
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
        addSemanticIndexes: false,
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
          _buildSectionHeader('Singer Queue ($queueLength)', (c, r) => _buildQueueContent(r, isExpanded: true), actions: [
            IconButton(
              icon: const Icon(Icons.history, color: AppTheme.accentPink),
              tooltip: 'Performance History',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showHistoryDialog(),
            ),
            const SizedBox(width: 8),
          ]),
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



  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final history = ref.watch(sessionStateProvider).history;
            return AlertDialog(
              title: const Text('Performance History', style: TextStyle(color: AppTheme.accentPink)),
              content: SizedBox(
                width: 500,
                height: 500,
                child: history.isEmpty
                    ? const Center(child: Text('No history yet.', style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                        itemCount: history.length,
                        addSemanticIndexes: false,
                        itemBuilder: (context, index) {
                          final song = history[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.bgInput,
                              child: Icon(Icons.history, color: AppTheme.textMuted),
                            ),
                            title: Text(song.displaySingerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(song.title, style: const TextStyle(color: AppTheme.textMuted)),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                final notifier = ref.read(sessionStateProvider.notifier);
                                final newSong = song.copyWith(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  addedAt: DateTime.now(),
                                  isRequest: false,
                                );
                                notifier.addToQueue(newSong);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${song.displaySingerName} added back to queue!'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        notifier.removeFromQueue(newSong.id);
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.replay, size: 16),
                              label: const Text('Call Back'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAiTriviaDialog(Song song) {
    String customPrompt = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Trivia: ${song.title}'),
        content: SizedBox(
          width: 800,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (song.aiTrivia != null)
                  MarkdownBody(
                    data: song.aiTrivia!,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white),
                      h3: const TextStyle(color: AppTheme.accentPurpleLight, fontWeight: FontWeight.bold, fontSize: 18),
                      tableHead: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPink),
                      tableBody: const TextStyle(color: Colors.white70),
                      tableBorder: TableBorder.all(color: AppTheme.border),
                    ),
                  )
                else
                  const Center(child: Text('No trivia available. It may be currently generating.', style: TextStyle(color: AppTheme.textMuted))),
                const SizedBox(height: 24),
                const Text('Fine-tune (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => customPrompt = val,
                  decoration: const InputDecoration(
                    labelText: 'Fine-tune Instruction',
                    hintText: 'e.g. Focus on the choreography',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
            onPressed: () {
              ref.read(sessionStateProvider.notifier).regenerateAiTrivia(song.id, customPrompt);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regenerating AI trivia in the background...')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(Song song, int index) {
    final queueLength = ref.read(queueProvider).where((s) => !s.isRequest).length;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.accentPurple,
        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(song.displaySingerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(song.title, style: const TextStyle(color: AppTheme.textMuted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (index > 0)
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.white70),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              onPressed: () => ref.read(sessionStateProvider.notifier).moveQueueItem(song.id, -1),
            ),
          if (index < queueLength - 1)
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 18, color: Colors.white70),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              onPressed: () => ref.read(sessionStateProvider.notifier).moveQueueItem(song.id, 1),
            ),
          if (song.duetSingerName != null && song.duetSingerName!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20, color: Colors.blueAccent),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              onPressed: () => ref.read(sessionStateProvider.notifier).swapDuetSingers(song.id),
            ),
          IconButton(
            icon: const Icon(Icons.psychology, color: AppTheme.accentPurple, size: 20),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            onPressed: () => _showAiTriviaDialog(song),
            tooltip: 'View AI Trivia',
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white70, size: 20),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            onPressed: () => _showEditSingersDialog(song),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            onPressed: () {
              final notifier = ref.read(sessionStateProvider.notifier);
              notifier.removeFromQueue(song.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${song.displaySingerName} removed from queue.'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      notifier.addToQueue(song);
                    },
                  ),
                ),
              );
            },
          ),
        ],
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
            Text('Requested by: ${req.displaySingerName}', style: const TextStyle(fontSize: 12)),
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
    final duetNameController = TextEditingController();
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
                decoration: const InputDecoration(labelText: 'Primary Singer'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: duetNameController,
                decoration: const InputDecoration(labelText: 'Duet Singer (Optional)'),
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
                final duetName = duetNameController.text.trim();
                ref.read(sessionStateProvider.notifier).approveRequest(
                  req.id, 
                  assignedSinger: assignedName.isEmpty ? null : assignedName,
                  assignedDuetSinger: duetName.isEmpty ? null : duetName,
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

  void _showEditSingersDialog(Song song) {
    final primaryController = TextEditingController(text: song.requestedByName);
    final duetController = TextEditingController(text: song.duetSingerName ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Singers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: primaryController,
                decoration: const InputDecoration(labelText: 'Primary Singer'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: duetController,
                decoration: const InputDecoration(labelText: 'Duet Singer (Optional)'),
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
                ref.read(sessionStateProvider.notifier).editSongSingers(
                  song.id,
                  primaryController.text.trim().isEmpty ? 'Unknown' : primaryController.text.trim(),
                  duetController.text.trim().isEmpty ? null : duetController.text.trim(),
                );
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
    final duetNameController = TextEditingController();
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
                decoration: const InputDecoration(labelText: 'Primary Singer Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: duetNameController,
                decoration: const InputDecoration(labelText: 'Duet Singer (Optional)'),
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
                  isLocal: librarySong.source != 'youtube' && librarySong.source != 'smule',
                  requestedBy: hostUser?.id ?? 'host',
                  requestedByName: hostNameController.text.trim().isEmpty ? 'Host' : hostNameController.text.trim(),
                  duetSingerName: duetNameController.text.trim().isEmpty ? null : duetNameController.text.trim(),
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
          const SizedBox(height: 8),
          TextField(
            controller: _timerMessageController,
            decoration: const InputDecoration(
              hintText: 'Custom message',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.timer, size: 16),
                label: const Text('1 Min'),
                onPressed: () {
                  ref.read(sessionStateProvider.notifier).pushCountdown(60);
                  ref.read(sessionStateProvider.notifier).pushAnnouncement(_timerMessageController.text.trim());
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.timer, size: 16),
                label: const Text('3 Min'),
                onPressed: () {
                  ref.read(sessionStateProvider.notifier).pushCountdown(180);
                  ref.read(sessionStateProvider.notifier).pushAnnouncement(_timerMessageController.text.trim());
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.timer, size: 16),
                label: const Text('5 Min'),
                onPressed: () {
                  ref.read(sessionStateProvider.notifier).pushCountdown(300);
                  ref.read(sessionStateProvider.notifier).pushAnnouncement(_timerMessageController.text.trim());
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.timer_outlined, size: 16),
                label: const Text('Custom'),
                onPressed: () => _showCustomTimerDialog(ref),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop, size: 16),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2)),
                onPressed: () {
                  ref.read(sessionStateProvider.notifier).pushCountdown(null);
                  ref.read(sessionStateProvider.notifier).pushAnnouncement(null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomTimerDialog(WidgetRef ref) {
    final TextEditingController minutesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('Custom Timer', style: TextStyle(color: AppTheme.textMain)),
          content: TextField(
            controller: minutesController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter minutes',
              suffixText: 'min',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final mins = int.tryParse(minutesController.text.trim());
                if (mins != null && mins > 0) {
                  ref.read(sessionStateProvider.notifier).pushCountdown(mins * 60);
                  ref.read(sessionStateProvider.notifier).pushAnnouncement(_timerMessageController.text.trim());
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
              child: const Text('Start'),
            ),
          ],
        );
      },
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

  Widget _buildServerStatusCard(LocalServerService server, BuildContext context, {Widget? bottomAction}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: server.isRunning ? AppTheme.accentPurple.withOpacity(0.1) : AppTheme.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: server.isRunning ? AppTheme.accentPurple : AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(server.isRunning ? Icons.wifi : Icons.wifi_off, color: server.isRunning ? AppTheme.accentPurpleLight : AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(server.isRunning ? 'Server is Live' : 'Server Offline', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                if (server.isRunning) ...[
                  const Text('Attendees can join at:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Tooltip(
                    message: 'Click to copy IP Address',
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: server.ipAddress ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP Address copied to clipboard')));
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('http://${server.ipAddress}:8080', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy, size: 14, color: AppTheme.accentPurpleLight),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Text('Start the server to allow attendees to join.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
                if (bottomAction != null) ...[
                  const SizedBox(height: 12),
                  bottomAction,
                ],
              ],
            ),
          ),
          if (server.isRunning)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(left: 8),
              child: QrImageView(
                data: 'http://${server.ipAddress}:8080',
                version: QrVersions.auto,
                size: 90.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkConfigContent(WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final server = ref.read(localServerProvider);
        
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
              const SizedBox(height: 24),
              const Text('Local Server Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildServerStatusCard(
                server,
                context,
                bottomAction: ElevatedButton.icon(
                  onPressed: () async {
                    if (server.isRunning) {
                      server.stopServer();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Server stopped.'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      await server.startServer();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Server started successfully at ${server.ipAddress}:8080!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                    setLocalState(() {});
                    setState(() {}); // Updates the background screen behind the dialog too
                  },
                  icon: Icon(server.isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(server.isRunning ? 'Stop Server' : 'Start Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: server.isRunning ? AppTheme.bgDark : AppTheme.accentPurple,
                    foregroundColor: server.isRunning ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Co-Host Access', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Host PIN Code', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Share this 4-digit code with trusted Co-Hosts', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        SelectableText(
                          ref.watch(hostSecurityProvider).pin,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppTheme.accentPink),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border, height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final token = ref.read(hostSecurityProvider.notifier).generateToken();
                          final ip = ref.read(localServerProvider).ipAddress ?? 'localhost';
                          final url = 'http://$ip:8080/?cohost_token=$token';
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('One-Time Link copied to clipboard! (It expires after 1 use)'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('Copy One-Time Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bgDark,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('AI Teleprompter & Trivia', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable AI Features', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Generates intro scripts and fun facts via Local LLM.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      value: settings.aiEnabled,
                      activeColor: AppTheme.accentPurple,
                      onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(aiEnabled: val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (settings.aiEnabled) ...[
                      const Divider(color: AppTheme.border, height: 24),
                      DropdownButtonFormField<String>(
                        value: settings.llmProvider,
                        decoration: const InputDecoration(labelText: 'Local LLM Provider'),
                        items: ['LM Studio', 'Ollama'].map((String p) {
                          return DropdownMenuItem<String>(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(llmProvider: val),
                        dropdownColor: AppTheme.bgDark,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: settings.llmUrl,
                        decoration: const InputDecoration(labelText: 'LLM URL (e.g. http://localhost:1234)'),
                        onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(llmUrl: val),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: settings.llmModel,
                        decoration: const InputDecoration(labelText: 'Model Name (e.g. local-model)'),
                        onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(llmModel: val),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: settings.aiLanguages,
                        decoration: const InputDecoration(labelText: 'Target Languages (Comma separated)'),
                        onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(aiLanguages: val),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetworkConfigTile() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Network & Event Config', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight)),
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showFullscreenDialog('Network & Event Config', (c, r) => _buildNetworkConfigContent(r)),
            )
          ]
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildNetworkConfigContent(ref),
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
          const Text('Google Sheets Webhook URL', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: settings.googleSheetsWebhookUrl,
            decoration: const InputDecoration(hintText: 'https://script.google.com/...'),
            onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(googleSheetsWebhookUrl: val),
          ),
          const SizedBox(height: 8),
          const Text('Used for automated performance logging.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 16),
          const Text('Smule Default Username', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: settings.smuleDefaultUsername,
            decoration: const InputDecoration(hintText: 'e.g. JasonDerulo'),
            onChanged: (val) => ref.read(settingsProvider.notifier).updateSettings(smuleDefaultUsername: val),
          ),
          const SizedBox(height: 8),
          const Text('Used as the default search when looking for Smule performances.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
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

  Widget _buildAiPromptsTile() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AI Agent Prompts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showFullscreenDialog('AI Agent Prompts', (c, r) => const SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16.0), child: AiPromptsConfigWidget()))),
            )
          ]
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: AiPromptsConfigWidget(),
          ),
        ],
      ),
    );
  }
}

class InteractiveHoverMenu extends StatefulWidget {
  final Widget child;
  final Widget menuWidget;
  final double width;

  const InteractiveHoverMenu({
    super.key,
    required this.child,
    required this.menuWidget,
    this.width = 420,
  });

  @override
  State<InteractiveHoverMenu> createState() => _InteractiveHoverMenuState();
}

class _InteractiveHoverMenuState extends State<InteractiveHoverMenu> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovering = false;
  bool _isHoveringMenu = false;

  void _showMenu() {
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: widget.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(-widget.width + 40, 48),
            child: MouseRegion(
              onEnter: (_) {
                _isHoveringMenu = true;
              },
              onExit: (_) {
                _isHoveringMenu = false;
                _checkHideMenu();
              },
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: widget.menuWidget,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _checkHideMenu() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && !_isHovering && !_isHoveringMenu) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovering = true;
          _showMenu();
        },
        onExit: (_) {
          _isHovering = false;
          _checkHideMenu();
        },
        child: widget.child,
      ),
    );
  }
}
