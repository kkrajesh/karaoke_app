import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/session_state_provider.dart';

class ReactionPadCard extends StatelessWidget {
  final String title;
  final String role;

  const ReactionPadCard({super.key, required this.title, required this.role});

  void _showFullscreenDialog(BuildContext context) {
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
            child: Column(
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
                Expanded(child: SingleChildScrollView(child: ReactionPad(role: role, isCompact: false))),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentPurpleLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showFullscreenDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReactionPad(role: role, isCompact: true),
        ],
      ),
    );
  }
}

class ReactionPad extends ConsumerStatefulWidget {
  final String role;
  final bool isCompact;

  const ReactionPad({super.key, required this.role, this.isCompact = false});

  @override
  ConsumerState<ReactionPad> createState() => _ReactionPadState();
}

class _ReactionPadState extends ConsumerState<ReactionPad> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendReaction(bool isEmoji, String value) {
    if (value.isNotEmpty) {
      ref.read(sessionStateProvider.notifier).sendReaction(widget.role, value, isEmoji: isEmoji);
      if (!isEmoji) {
        _commentController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      // Single line layout
      return Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmojiBtn('👏', () => _sendReaction(true, '👏'), compact: true),
              _EmojiBtn('🔥', () => _sendReaction(true, '🔥'), compact: true),
              _EmojiBtn('🎤', () => _sendReaction(true, '🎤'), compact: true),
              _EmojiBtn('😂', () => _sendReaction(true, '😂'), compact: true),
              _EmojiBtn('💖', () => _sendReaction(true, '💖'), compact: true),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Comment...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12),
              onSubmitted: (value) => _sendReaction(false, value),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => _sendReaction(false, _commentController.text.trim()),
            icon: const Icon(Icons.send, size: 14),
          ),
        ],
      );
    }

    // Expanded / Original Vertical Layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _EmojiBtn('👏', () => _sendReaction(true, '👏')),
            _EmojiBtn('🔥', () => _sendReaction(true, '🔥')),
            _EmojiBtn('🎤', () => _sendReaction(true, '🎤')),
            _EmojiBtn('😂', () => _sendReaction(true, '😂')),
            _EmojiBtn('💖', () => _sendReaction(true, '💖')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Say something encouraging...',
                  isDense: true,
                ),
                onSubmitted: (value) => _sendReaction(false, value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => _sendReaction(false, _commentController.text.trim()),
              icon: const Icon(Icons.send, size: 20),
            ),
          ],
        )
      ],
    );
  }
}

class _EmojiBtn extends StatelessWidget {
  final String emoji;
  final VoidCallback onPressed;
  final bool compact;

  const _EmojiBtn(this.emoji, this.onPressed, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
      decoration: const BoxDecoration(
        color: AppTheme.bgInput,
        shape: BoxShape.circle,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(compact ? 4.0 : 8.0),
          child: Text(emoji, style: TextStyle(fontSize: compact ? 16 : 20)),
        ),
      ),
    );
  }
}
