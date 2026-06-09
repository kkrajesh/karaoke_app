import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/youtube_service.dart';
import '../services/smule_service.dart';
import '../providers/app_state_provider.dart';

import '../models/song.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:vox_player_core/vox_player_core.dart';
class PlayerScreen extends ConsumerStatefulWidget {
  final Song? song;
  final bool isPublicDisplay;

  const PlayerScreen({super.key, this.song, this.isPublicDisplay = false});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  // Web Player
  YoutubePlayerController? _webYtController;
  VideoPlayerController? _webLocalController;
  
  // Native Player (Windows/Android)
  Player? _nativePlayer;
  VideoController? _nativeController;
  bool _isLoadingNative = true;
  String? _nativeError;

  // Sequence Tracking
  PerformanceProfile? _profile;
  Sequence? _activeSequence;
  int _currentSequenceIndex = 0;
  Timer? _webPositionTimer;
  StreamSubscription<Duration>? _nativePositionSub;

  @override
  void initState() {
    super.initState();
    print('[PlayerScreen] initState called for song: ${widget.song?.id}');

    if (!kIsWeb) {
      _nativePlayer = Player();
      _nativeController = VideoController(
        _nativePlayer!, 
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration: Platform.isWindows,
        ),
      );
    }
    
    if (widget.song != null) {
      _initSong(widget.song!);
    }
  }





  Future<void> _initSong(Song newSong) async {
    // 1. Fetch performance profile if a sequence is requested
    if (newSong.activeSequenceName != null) {
      final mmId = newSong.isLocal ? newSong.id : 'YT_${newSong.videoId}';
      final saveDir = VoxAiTrackingService.instance.getArtifactDirectory(mmId, newSong.title);
      try {
        _profile = await PerformanceProfileService.loadProfile(saveDir);
        _activeSequence = _profile?.sequences.firstWhere((s) => s.name == newSong.activeSequenceName);
        _currentSequenceIndex = 0;
      } catch (e) {
        print('Error loading profile for sequence: $e');
      }
    }

    if (kIsWeb) {
      if (newSong.videoId.startsWith('https://www.smule.com')) {
        await _initWebSmulePlayer(newSong.videoId);
      } else if (newSong.isLocal) {
        await _initWebLocalPlayer(newSong.videoId);
      } else {
        _initWebYtPlayer(newSong.videoId);
      }
    } else {
      await _initNativePlayer(newSong);
    }
    
    _setupSequenceListeners();
  }

  Future<void> _initWebSmulePlayer(String smuleUrl) async {
    final smuleService = ref.read(smuleServiceProvider);
    final streamUrl = await smuleService.getMediaUrl(smuleUrl);
    if (streamUrl != null && mounted) {
      _webLocalController = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await _webLocalController!.initialize();
      _webLocalController!.play();
      setState(() {});
    }
  }

  void _initWebYtPlayer(String videoId) {
    _webYtController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  Future<void> _initWebLocalPlayer(String path) async {
    final ip = ref.read(clientHostIpProvider) ?? '127.0.0.1';
    final url = 'http://$ip:8080/local-media?path=${Uri.encodeComponent(path)}';
    
    _webLocalController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _webLocalController!.initialize();
    _webLocalController!.play();
    if (mounted) setState(() {});
  }

  Future<void> _initNativePlayer(Song song) async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingNative = true;
          _nativeError = null;
        });
      }

      String? streamUrl;
      
      if (song.videoId.startsWith('https://www.smule.com')) {
        final smuleService = ref.read(smuleServiceProvider);
        streamUrl = await smuleService.getMediaUrl(song.videoId);
      } else if (song.isLocal) {
        final clientIp = ref.read(clientHostIpProvider);
        if (clientIp != null) {
          // Client: stream from host
          streamUrl = 'http://$clientIp:8080/local-media?path=${Uri.encodeComponent(song.videoId)}';
        } else {
          // Host: play directly, converting slashes for libmpv
          streamUrl = song.videoId.replaceAll('\\', '/');
          if (!streamUrl.startsWith('file:///')) {
            if (streamUrl.startsWith('/')) {
              streamUrl = 'file://$streamUrl';
            } else {
              streamUrl = 'file:///$streamUrl';
            }
          }
        }
      } else {
        final ytService = ref.read(youtubeServiceProvider);
        streamUrl = await ytService.getVideoStreamUrl(song.videoId);
      }
      
      if (streamUrl != null && mounted) {
        await _nativePlayer!.open(Media(streamUrl), play: true);
        _nativePlayer!.play();
        setState(() {
          _isLoadingNative = false;
        });
      } else {
        throw Exception("Could not extract video stream");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nativeError = e.toString();
          _isLoadingNative = false;
        });
      }
    }
  }

  void _setupSequenceListeners() {
    if (_activeSequence == null || _activeSequence!.segments.isEmpty) return;

    if (!kIsWeb && _nativePlayer != null) {
      _nativePositionSub = _nativePlayer!.stream.position.listen((pos) {
        _enforceSequenceBoundary(pos);
      });
    } else if (kIsWeb) {
      _webPositionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        Duration currentPosition = Duration.zero;
        if (_webYtController != null) {
          final seconds = await _webYtController!.currentTime;
          currentPosition = Duration(milliseconds: (seconds * 1000).toInt());
        } else if (_webLocalController != null) {
          currentPosition = _webLocalController!.value.position;
        }
        _enforceSequenceBoundary(currentPosition);
      });
    }
  }

  void _enforceSequenceBoundary(Duration currentPosition) {
    if (_activeSequence == null || _activeSequence!.segments.isEmpty) return;
    if (_currentSequenceIndex >= _activeSequence!.segments.length) return;

    final currentSegment = _activeSequence!.segments[_currentSequenceIndex];
    
    // Check if we need to jump to the start of the current segment
    // We add a tiny buffer so we don't infinitely seek backwards
    if (currentPosition < currentSegment.startTime - const Duration(milliseconds: 1000)) {
       _seekTo(currentSegment.startTime);
       return;
    }

    // Check if we reached the end of the current segment
    if (currentPosition >= currentSegment.endTime) {
      _currentSequenceIndex++;
      if (_currentSequenceIndex < _activeSequence!.segments.length) {
        // Jump to next segment
        _seekTo(_activeSequence!.segments[_currentSequenceIndex].startTime);
      } else {
        // End of sequence - pause playback
        if (!kIsWeb && _nativePlayer != null) {
          _nativePlayer!.pause();
        } else if (kIsWeb && _webYtController != null) {
          _webYtController!.pauseVideo();
        } else if (kIsWeb && _webLocalController != null) {
          _webLocalController!.pause();
        }
      }
    }
  }

  void _seekTo(Duration position) {
    if (!kIsWeb && _nativePlayer != null) {
      _nativePlayer!.seek(position);
    } else if (kIsWeb && _webYtController != null) {
      _webYtController!.seekTo(seconds: position.inSeconds.toDouble(), allowSeekAhead: true);
    } else if (kIsWeb && _webLocalController != null) {
      _webLocalController!.seekTo(position);
    }
  }

  @override
  void dispose() {
    print('[PlayerScreen] dispose called for song: ${widget.song?.id}');
    _nativePositionSub?.cancel();
    _webPositionTimer?.cancel();
    _webYtController?.close();
    _webLocalController?.dispose();
    if (!kIsWeb) {
      // Async dispose to prevent texture access violation crashes when unmounting
      final playerToDispose = _nativePlayer;
      Future.delayed(const Duration(milliseconds: 500), () {
        playerToDispose?.dispose();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (widget.song == null) {
        return Container(color: Colors.black);
      }
      
      if (widget.song!.isLocal || widget.song!.videoId.startsWith('https://www.smule.com')) {
        if (_webLocalController != null && _webLocalController!.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _webLocalController!.value.aspectRatio,
              child: VideoPlayer(_webLocalController!),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      } else {
        if (_webYtController != null) {
          return Center(
            child: YoutubePlayer(
              controller: _webYtController!,
              aspectRatio: 16 / 9,
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }
    }

    // Native Build
    if (_nativeError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading video: $_nativeError', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            if (_nativeController != null)
              Video(controller: _nativeController!),
            
              if (_isLoadingNative || widget.song == null)
              Container(
                color: Colors.black,
                child: Center(
                  child: widget.song != null ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accentPink),
                      SizedBox(height: 16),
                      Text('Loading next song...', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ) : const SizedBox(),
                ),
              ),

              if (widget.song != null && !widget.song!.isLocal && !widget.isPublicDisplay)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Builder(
                    builder: (context) {
                      final result = VoxSearchResult(
                        id: widget.song!.id,
                        title: widget.song!.title,
                        artist: widget.song!.displaySingerName,
                        url: widget.song!.videoId,
                        sourceType: widget.song!.videoId.startsWith('https://www.smule.com') ? 'smule' : 'youtube',
                      );
                      return AiQueueButton(result: result, isVisible: true);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
