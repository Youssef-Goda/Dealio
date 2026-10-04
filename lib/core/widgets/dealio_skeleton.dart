import 'package:flutter/material.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
// Using near-black greys so the shimmer blends perfectly in dark mode
// and stays subtle enough in light mode.
const _kBase = Color(0xFF1E1E1E);
const _kHi = Color(0xFF2C2C2C);
const _kLightBase = Color(0xFFECECEC);
const _kLightHi = Color(0xFFF9F9F9);

// ─────────────────────────────────────────────────────────────────────────────
// 1. DealioShimmer — the core animated building block
// ─────────────────────────────────────────────────────────────────────────────

/// A drop-in shimmer box.  Specify [width], [height] and [borderRadius].
/// Inherits dark/light palette from current theme automatically.
class DealioShimmer extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius; 

  const DealioShimmer({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<DealioShimmer> createState() => _DealioShimmerState();
}

class _DealioShimmerState extends State<DealioShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? _kBase : _kLightBase;
    final hi = isDark ? _kHi : _kLightHi;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, hi, _anim.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. AdminStatCardSkeleton — 4 stat cards in a row
// ─────────────────────────────────────────────────────────────────────────────

class AdminStatCardSkeleton extends StatelessWidget {
  const AdminStatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // icon box
                DealioShimmer(width: 44, height: 44, borderRadius: 12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DealioShimmer(width: 70, height: 11, borderRadius: 6),
                      const SizedBox(height: 8),
                      DealioShimmer(width: 48, height: 22, borderRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. AdminTableSkeleton — dark header + 8 shimmering rows
// ─────────────────────────────────────────────────────────────────────────────

/// A skeleton that matches the column layout of the Products/Users custom table.
/// [rowCount] — how many shimmer rows to show (default 8).
class AdminTableSkeleton extends StatelessWidget {
  final int rowCount;

  const AdminTableSkeleton({super.key, this.rowCount = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Dark header bar ──────────────────────────────────────────────
          _SkeletonHeader(),
          // ── Rows ─────────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: rowCount,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03),
              ),
              itemBuilder: (_, __) => const _SkeletonRow(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Seamless — matches real table header (cardColor + bottom divider)
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: const [
          SizedBox(width: 50), // checkbox
          Expanded(flex: 1, child: _HeaderLabel('SKU')),
          Expanded(flex: 4, child: _HeaderLabel('Name')),
          Expanded(flex: 2, child: _HeaderLabel('Price / Email')),
          SizedBox(width: 80, child: _HeaderLabel('Image', center: true)),
          Expanded(flex: 1, child: _HeaderLabel('Qty', center: true)),
          Expanded(flex: 2, child: _HeaderLabel('Status', center: true)),
          SizedBox(width: 80, child: _HeaderLabel('Actions', center: true)),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  final bool center;

  const _HeaderLabel(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: center
          ? Center(child: child)
          : Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            // Checkbox placeholder
            const SizedBox(
              width: 50,
              child: Center(
                child: DealioShimmer(width: 18, height: 18, borderRadius: 4),
              ),
            ),
            // SKU
            Expanded(
              flex: 1,
              child: Center(
                child: DealioShimmer(width: 52, height: 12, borderRadius: 6),
              ),
            ),
            // Name
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    DealioShimmer(height: 12, borderRadius: 6),
                    SizedBox(height: 6),
                    DealioShimmer(width: 100, height: 10, borderRadius: 6),
                  ],
                ),
              ),
            ),
            // Price / Email
            Expanded(
              flex: 2,
              child: Center(
                child: DealioShimmer(width: 70, height: 13, borderRadius: 6),
              ),
            ),
            // Image circle
            const SizedBox(
              width: 80,
              child: Center(
                child: DealioShimmer(width: 40, height: 40, borderRadius: 8),
              ),
            ),
            // Qty
            Expanded(
              flex: 1,
              child: Center(
                child: DealioShimmer(width: 28, height: 13, borderRadius: 6),
              ),
            ),
            // Status badge
            Expanded(
              flex: 2,
              child: Center(
                child: DealioShimmer(width: 70, height: 24, borderRadius: 20),
              ),
            ),
            // Eye icon
            SizedBox(
              width: 80,
              child: Center(
                child: DealioShimmer(width: 38, height: 38, borderRadius: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
