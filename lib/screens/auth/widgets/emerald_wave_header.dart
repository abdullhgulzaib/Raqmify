import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Displays the official Raqmify brand mark PNG without color tint distortion.
class RaqmifyBrandLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const RaqmifyBrandLogo({
    super.key,
    this.size = 64,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: (showGlow ? AppColors.teal : Colors.black)
                .withValues(alpha: showGlow ? 0.26 : 0.22),
            blurRadius: showGlow ? 28 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/raqmify_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// Renders the signature sweeping dark-emerald curved backdrop with thin gold edge accent.
class EmeraldWaveBackdrop extends StatelessWidget {
  final double heightFactor;
  final bool highRightWave;

  const EmeraldWaveBackdrop({
    super.key,
    this.heightFactor = 0.62,
    this.highRightWave = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EmeraldWavePainter(
        heightFactor: heightFactor,
        highRightWave: highRightWave,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _EmeraldWavePainter extends CustomPainter {
  final double heightFactor;
  final bool highRightWave;

  const _EmeraldWavePainter({
    required this.heightFactor,
    required this.highRightWave,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final leftY = h * heightFactor;
    final rightY = highRightWave ? h * (heightFactor - 0.14) : h * (heightFactor - 0.05);

    // 1. Main sweeping dark emerald gradient shape
    final mainPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, rightY)
      ..cubicTo(
        w * 0.72,
        rightY + (h * 0.02),
        w * 0.36,
        leftY + (h * 0.06),
        0,
        leftY,
      )
      ..close();

    final mainPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF04261F),
          Color(0xFF093E33),
          Color(0xFF073229),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, leftY + 40));

    canvas.drawPath(mainPath, mainPaint);

    // 2. Subtle silky darker emerald diagonal ribbon sweep inside the hero
    canvas.save();
    canvas.clipPath(mainPath);

    final innerWave = Path()
      ..moveTo(w * 0.25, 0)
      ..cubicTo(
        w * 0.45,
        h * 0.18,
        w * 0.72,
        h * 0.12,
        w,
        h * 0.26,
      )
      ..lineTo(w, 0)
      ..close();

    final ribbonPaint = Paint()
      ..color = const Color(0xFF021C16).withValues(alpha: 0.48);
    canvas.drawPath(innerWave, ribbonPaint);

    final softGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, 0.05),
        radius: 0.85,
        colors: [
          AppColors.teal.withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, leftY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, leftY), softGlowPaint);

    canvas.restore();

    // 3. Delicate gold contour accent along the right sweep
    final goldStrokePath = Path()
      ..moveTo(w * 0.32, leftY + (h * 0.036))
      ..cubicTo(
        w * 0.58,
        leftY + (h * 0.035),
        w * 0.80,
        rightY + (h * 0.035),
        w,
        rightY + (h * 0.014),
      );

    final goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          AppColors.mutedGold.withValues(alpha: 0.0),
          AppColors.mutedGold.withValues(alpha: 0.85),
          AppColors.mutedGold,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(w * 0.3, rightY, w * 0.7, h * 0.22));

    canvas.drawPath(goldStrokePath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant _EmeraldWavePainter oldDelegate) =>
      oldDelegate.heightFactor != heightFactor ||
      oldDelegate.highRightWave != highRightWave;
}
