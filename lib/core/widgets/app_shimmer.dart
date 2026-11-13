import 'package:flutter/material.dart';

/// Pure Flutter shimmer loading skeleton widget (U1).
class AppShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shapeBorder,
  });

  const AppShimmer.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shapeBorder = const CircleBorder();

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1F2B28) : const Color(0xFFE4ECE9);
    final highlightColor = isDark ? const Color(0xFF2C3E3A) : const Color(0xFFF4F8F7);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: widget.shapeBorder != null
              ? ShapeDecoration(
                  shape: widget.shapeBorder!,
                  gradient: LinearGradient(
                    begin: Alignment(_animation.value - 1, 0),
                    end: Alignment(_animation.value, 0),
                    colors: [baseColor, highlightColor, baseColor],
                  ),
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment(_animation.value - 1, 0),
                    end: Alignment(_animation.value, 0),
                    colors: [baseColor, highlightColor, baseColor],
                  ),
                ),
        );
      },
    );
  }
}

/// Shimmer placeholder list for loading states (U1)
class ShimmerListPlaceholder extends StatelessWidget {
  final int itemCount;

  const ShimmerListPlaceholder({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2826) : Colors.white;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3E3A) : const Color(0xFFE4ECE9),
            ),
          ),
          child: const Row(
            children: [
              AppShimmer(width: 44, height: 44, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer(width: 130, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    AppShimmer(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              AppShimmer(width: 60, height: 18, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}
