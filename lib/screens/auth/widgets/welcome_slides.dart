import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class HeroControlDeckSlide extends StatelessWidget {
  final VoidCallback onActionTap;

  const HeroControlDeckSlide({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 222,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 24,
              bottom: 14,
              child: Transform.rotate(
                angle: -0.09,
                child: Container(
                  width: 144,
                  height: 148,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFDCF0E8), Color(0xFFCBE4D8)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: CustomPaint(painter: SparklinePainter()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 34,
              top: 10,
              child: Transform.rotate(
                angle: -0.17,
                child: Container(
                  width: 138,
                  height: 108,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A4336), Color(0xFF03211B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MiniBar(height: 18, colors: [Color(0xFF7AF9C9), Color(0xFF16C79A)]),
                        MiniBar(height: 46, colors: [Color(0xFFF3C867), Color(0xFFD49D35)]),
                        MiniBar(height: 30, colors: [Color(0xFF2FE4AA), Color(0xFF119F7A)]),
                        MiniBar(height: 36, colors: [Color(0xFF42E6B2), Color(0xFF15AD83)]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 16,
              child: Transform.rotate(
                angle: 0.08,
                child: GestureDetector(
                  onTap: onActionTap,
                  child: Container(
                    width: 148,
                    height: 140,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFF3F7F5)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF04221B).withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your money,\nyour control.',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0E241E),
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 78,
                            height: 32,
                            decoration: const ShapeDecoration(
                              color: Color(0xFF073A2E),
                              shape: StadiumBorder(),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplitVaultShowcaseSlide extends StatelessWidget {
  final VoidCallback onActionTap;

  const SplitVaultShowcaseSlide({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 222,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 34,
              top: 22,
              child: Transform.rotate(
                angle: -0.10,
                child: Container(
                  width: 152,
                  height: 124,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0C4C3D), Color(0xFF04261E)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SplitVault',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedGold,
                        ),
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          AvatarDot(label: 'A', color: Color(0xFF16C79A)),
                          SizedBox(width: 6),
                          AvatarDot(label: 'H', color: Color(0xFFD4AF6B)),
                          SizedBox(width: 6),
                          AvatarDot(label: 'Z', color: Color(0xFF60A5FA)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Roommate Group',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: 18,
              child: Transform.rotate(
                angle: 0.07,
                child: GestureDetector(
                  onTap: onActionTap,
                  child: Container(
                    width: 156,
                    height: 132,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF04221B).withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split shared bills\nwithout friction.',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0E241E),
                            height: 1.25,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: const ShapeDecoration(
                            color: Color(0xFFE5F6F0),
                            shape: StadiumBorder(),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: Color(0xFF073A2E),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Auto Settle',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF073A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SecurityPdfShowcaseSlide extends StatelessWidget {
  final VoidCallback onActionTap;

  const SecurityPdfShowcaseSlide({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 222,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 34,
              top: 22,
              child: Transform.rotate(
                angle: -0.09,
                child: Container(
                  width: 148,
                  height: 124,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFDCF0E8), Color(0xFFC5E1D4)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF073A2E),
                        size: 26,
                      ),
                      const Spacer(),
                      Text(
                        '4-Digit Vault PIN\n& Cloud Sync',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF073A2E),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: 18,
              child: Transform.rotate(
                angle: 0.06,
                child: GestureDetector(
                  onTap: onActionTap,
                  child: Container(
                    width: 156,
                    height: 132,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF04221B).withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Instant PDF\nstatements.',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0E241E),
                            height: 1.25,
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 82,
                            height: 32,
                            decoration: const ShapeDecoration(
                              color: Color(0xFF073A2E),
                              shape: StadiumBorder(),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniBar extends StatelessWidget {
  final double height;
  final List<Color> colors;

  const MiniBar({super.key, required this.height, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class AvatarDot extends StatelessWidget {
  final String label;
  final Color color;

  const AvatarDot({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF03211B),
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(4, h * 0.78)
      ..cubicTo(w * 0.20, h * 0.85, w * 0.28, h * 0.52, w * 0.44, h * 0.58)
      ..cubicTo(w * 0.60, h * 0.64, w * 0.68, h * 0.25, w * 0.92, h * 0.20);

    final fillPath = Path.from(path)
      ..lineTo(w * 0.92, h)
      ..lineTo(4, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF16C79A).withValues(alpha: 0.26),
          const Color(0xFF16C79A).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF109372)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    final dotFill = Paint()..color = const Color(0xFF0B6D55);
    final dotHalo = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final points = [
      Offset(w * 0.44, h * 0.58),
      Offset(w * 0.92, math.max(8, h * 0.20)),
    ];
    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, dotHalo);
      canvas.drawCircle(pt, 2.7, dotFill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
