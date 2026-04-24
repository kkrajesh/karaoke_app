import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StyledCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const StyledCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<StyledCard> createState() => _StyledCardState();
}

class _StyledCardState extends State<StyledCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgInput : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? AppTheme.accentPurple : Colors.transparent,
              width: 2,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
