import 'package:dealio/core/constants/colors.dart';
import 'package:flutter/material.dart';

/// A reusable interactive star rating input widget.
///
/// Tapping a star sets the rating; hovering highlights up to that star on web/desktop.
/// Shows a clear "tap to rate" hint text when [value] is 0.
class StarRatingInput extends StatefulWidget {
  final int value; // 0–5
  final ValueChanged<int> onChanged;
  final double starSize;
  final bool readOnly;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.starSize = 32,
    this.readOnly = false,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  int _hovered = 0;

  @override
  Widget build(BuildContext context) {
    final effective = _hovered > 0 ? _hovered : widget.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= effective;
        return GestureDetector(
          onTap: widget.readOnly ? null : () => widget.onChanged(star),
          child: MouseRegion(
            onEnter: widget.readOnly ? null : (_) => setState(() => _hovered = star),
            onExit: widget.readOnly ? null : (_) => setState(() => _hovered = 0),
            cursor: widget.readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                key: ValueKey('$star-$filled'),
                color: filled ? AppColors.starAmber : AppColors.darkTextMuted,
                size: widget.starSize,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Read-only star display with optional fractional star support.
///
/// Shows filled, half-filled, or empty stars based on [rating].
class StarDisplay extends StatelessWidget {
  final double rating; // 0.0–5.0
  final double starSize;
  final Color? color;

  const StarDisplay({
    super.key,
    required this.rating,
    this.starSize = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.starAmber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final threshold = i + 1.0;
        IconData icon;
        if (rating >= threshold) {
          icon = Icons.star_rounded;
        } else if (rating >= threshold - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, color: c, size: starSize);
      }),
    );
  }
}
