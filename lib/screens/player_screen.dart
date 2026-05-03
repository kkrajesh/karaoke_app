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

class PlayerScreen extends ConsumerStatefulWidget {
  final Song? song;

  const PlayerScreen({super.key, this.song});

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

  @override
  void initState() {
    super.initState();
    print('[PlayerScreen] initState called for song: ${widget.song?.id}');

    if (!kIsWeb) {
      _nativePlayer = Player();
      _nativeController = VideoController(_nativePlayer!);
    }
    
    if (widget.song != null) {
      _initSong(widget.song!);
    }
  }





  void _initSong(Song newSong) {
    if (kIsWeb) {
      if (newSong.videoId.startsWith('https://www.smule.com')) {
        _initWebSmulePlayer(newSong.videoId);
      } else if (newSong.isLocal) {
        _initWebLocalPlayer(newSong.videoId);
      } else {
        _initWebYtPlayer(newSong.videoId);
      }
    } else {
      _initNativePlayer(newSong);
    }
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
        // Convert backslashes to forward slashes for libmpv, avoiding percent-encoding issues
        streamUrl = song.videoId.replaceAll('\\', '/');
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



  @override
  void dispose() {
    print('[PlayerScreen] dispose called for song: ${widget.song?.id}');
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
          ],
        ),
      ),
    );
  }
}
