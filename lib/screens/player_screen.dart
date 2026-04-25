import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/youtube_service.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String videoId;

  const PlayerScreen({super.key, required this.videoId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  // Web Player
  YoutubePlayerController? _webController;
  
  // Native Player (Windows/Android)
  late final Player _nativePlayer;
  late final VideoController _nativeController;
  bool _isLoadingNative = true;
  String? _nativeError;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _webController = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
    } else {
      _nativePlayer = Player();
      _nativeController = VideoController(_nativePlayer);
      _initNativePlayer(widget.videoId);
    }
  }

  Future<void> _initNativePlayer(String videoId) async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingNative = true;
          _nativeError = null;
        });
      }

      final ytService = ref.read(youtubeServiceProvider);
      final streamUrl = await ytService.getVideoStreamUrl(videoId);
      
      if (streamUrl != null && mounted) {
        await _nativePlayer.open(Media(streamUrl));
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
    if (oldWidget.videoId != widget.videoId) {
      if (kIsWeb) {
        _webController?.loadVideoById(videoId: widget.videoId);
      } else {
        _initNativePlayer(widget.videoId);
      }
    }
  }

  @override
  void dispose() {
    _webController?.close();
    if (!kIsWeb) {
      _nativePlayer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: YoutubePlayer(
          controller: _webController!,
          aspectRatio: 16 / 9,
        ),
      );
    }

    // Native Build
    if (_isLoadingNative) {
      return const Center(child: CircularProgressIndicator());
    }

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
        child: Video(controller: _nativeController),
      ),
    );
  }
}
