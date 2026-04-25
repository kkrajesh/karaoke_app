import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/youtube_service.dart';
import '../providers/app_state_provider.dart';

import '../models/song.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final Song song;

  const PlayerScreen({super.key, required this.song});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  // Web Player
  YoutubePlayerController? _webYtController;
  VideoPlayerController? _webLocalController;
  
  // Native Player (Windows/Android)
  late final Player _nativePlayer;
  late final VideoController _nativeController;
  bool _isLoadingNative = true;
  String? _nativeError;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      if (widget.song.isLocal) {
        _initWebLocalPlayer(widget.song.videoId);
      } else {
        _initWebYtPlayer(widget.song.videoId);
      }
    } else {
      _nativePlayer = Player();
      _nativeController = VideoController(_nativePlayer);
      _initNativePlayer(widget.song);
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
      
      if (song.isLocal) {
        // For native, we can just play the file path directly from disk
        streamUrl = 'file:///' + song.videoId.replaceAll('\\\\', '/');
      } else {
        final ytService = ref.read(youtubeServiceProvider);
        streamUrl = await ytService.getVideoStreamUrl(song.videoId);
      }
      
      if (streamUrl != null && mounted) {
        await _nativePlayer.open(Media(streamUrl), play: true);
        _nativePlayer.play();
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
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      if (kIsWeb) {
        if (widget.song.isLocal) {
          _webYtController?.close();
          _webYtController = null;
          _initWebLocalPlayer(widget.song.videoId);
        } else {
          _webLocalController?.dispose();
          _webLocalController = null;
          if (_webYtController != null) {
            _webYtController!.loadVideoById(videoId: widget.song.videoId);
          } else {
            _initWebYtPlayer(widget.song.videoId);
          }
        }
      } else {
        _initNativePlayer(widget.song);
      }
    }
  }

  @override
  void dispose() {
    _webYtController?.close();
    _webLocalController?.dispose();
    if (!kIsWeb) {
      _nativePlayer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (widget.song.isLocal) {
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
            Video(controller: _nativeController),
            if (_isLoadingNative)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
