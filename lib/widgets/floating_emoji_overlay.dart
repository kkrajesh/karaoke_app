import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_state_provider.dart';

class FloatingEmojiOverlay extends ConsumerStatefulWidget {
  const FloatingEmojiOverlay({super.key});

  @override
  ConsumerState<FloatingEmojiOverlay> createState() => _FloatingEmojiOverlayState();
}

class _FloatingEmojiOverlayState extends ConsumerState<FloatingEmojiOverlay> {
  final List<_FloatingEmoji> _activeEmojis = [];
  int _lastSeenCount = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionStateProvider, (previous, next) {
      final emojis = next.reactions.where((r) => r['isEmoji'] == true).toList();
      if (emojis.length > _lastSeenCount) {
        // New emojis added
        final newEmojis = emojis.sublist(_lastSeenCount);
        for (var e in newEmojis) {
          _spawnEmoji(e['value'] as String);
        }
      }
      _lastSeenCount = emojis.length;
      
      // If reactions were cleared (e.g. song change)
      if (emojis.isEmpty && _lastSeenCount > 0) {
        _lastSeenCount = 0;
      }
    });

    return Stack(
      children: _activeEmojis.map((e) {
        return _FloatingAnimatedEmoji(
          key: ValueKey(e.id),
          emoji: e.emoji,
          onComplete: () {
            setState(() {
              _activeEmojis.removeWhere((item) => item.id == e.id);
            });
          },
        );
      }).toList(),
    );
  }

  void _spawnEmoji(String emoji) {
    setState(() {
      _activeEmojis.add(_FloatingEmoji(
        id: DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
        emoji: emoji,
      ));
    });
  }
}

class _FloatingEmoji {
  final String id;
  final String emoji;
  _FloatingEmoji({required this.id, required this.emoji});
}

class _FloatingAnimatedEmoji extends StatefulWidget {
  final String emoji;
  final VoidCallback onComplete;

  const _FloatingAnimatedEmoji({super.key, required this.emoji, required this.onComplete});

  @override
  State<_FloatingAnimatedEmoji> createState() => _FloatingAnimatedEmojiState();
}

class _FloatingAnimatedEmojiState extends State<_FloatingAnimatedEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bottomAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _horizontalAnimation;
  
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + _random.nextInt(1000)),
    );

    _bottomAnimation = Tween<double>(begin: 0, end: 400 + _random.nextDouble() * 200).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    final drift = (_random.nextDouble() - 0.5) * 100; // random drift left or right
    _horizontalAnimation = Tween<double>(begin: 0, end: drift).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startLeft = 40.0 + _random.nextDouble() * 100.0; // Random starting X position near bottom left

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          bottom: 100 + _bottomAnimation.value,
          left: startLeft + _horizontalAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),
        );
      },
    );
  }
}
