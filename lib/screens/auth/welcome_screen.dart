import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/split_provider.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'widgets/emerald_wave_header.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  bool _isDemoLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _advanceSlideOrLogin() {
    if (_currentSlide < 2) {
      _pageController.animateToPage(
        _currentSlide + 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _openLogin();
    }
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleDemoLogin() async {
    if (_isDemoLoading) return;
    setState(() => _isDemoLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);

    await auth.demoLogin();
    expenseProvider.loadDemoData();
    splitProvider.loadDemoData();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Stack(
          children: [
            const Positioned.fill(
              child: EmeraldWaveBackdrop(
                heightFactor: 0.65,
                highRightWave: true,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                                child: Column(
                                  children: [
                                    const RaqmifyBrandLogo(
                                      size: 56,
                                      showGlow: true,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Raqmify',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'All your finances\nin one place.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 29,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Track spending, manage bills, set budgets,\nand grow your savings — effortlessly.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withValues(alpha: 0.78),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Layered 3D showcase carousel
                              Column(
                                children: [
                                  SizedBox(
                                    height: 226,
                                    child: PageView(
                                      controller: _pageController,
                                      physics: const BouncingScrollPhysics(),
                                      onPageChanged: (index) {
                                        setState(() => _currentSlide = index);
                                      },
                                      children: [
                                        _HeroControlDeckSlide(
                                          onActionTap: _advanceSlideOrLogin,
                                        ),
                                        _SplitVaultShowcaseSlide(
                                          onActionTap: _advanceSlideOrLogin,
                                        ),
                                        _SecurityPdfShowcaseSlide(
                                          onActionTap: _advanceSlideOrLogin,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (index) {
                                      final isActive = _currentSlide == index;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 240),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: isActive ? 8 : 7,
                                        height: isActive ? 8 : 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive
                                              ? const Color(0xFF073A2E)
                                              : const Color(0xFFC5D2CE),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),

                              // Bottom primary action area over crisp off-white canvas
                              Padding(
                                padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _openRegister,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF06342A),
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shadowColor: const Color(0xFF06342A)
                                              .withValues(alpha: 0.35),
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(horizontal: 22),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Center(
                                              child: Text(
                                                'Create an account',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const Align(
                                              alignment: Alignment.centerRight,
                                              child: Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: _openLogin,
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 12,
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFF4F5D59),
                                            ),
                                            children: [
                                              const TextSpan(text: 'Have an account? '),
                                              TextSpan(
                                                text: 'Log in',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF06342A),
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: const Color(0xFF06342A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton.icon(
                                      onPressed: _isDemoLoading ? null : _handleDemoLogin,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.textMuted,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        minimumSize: const Size(0, 32),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: _isDemoLoading
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.deepEmerald,
                                              ),
                                            )
                                          : const Icon(Icons.bolt_rounded, size: 15),
                                      label: Text(
                                        _isDemoLoading
                                            ? 'Loading Demo...'
                                            : 'Quick Demo Mode',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroControlDeckSlide extends StatelessWidget {
  final VoidCallback onActionTap;

  const _HeroControlDeckSlide({required this.onActionTap});

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
            // Back frosted mint trend card
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
                        child: CustomPaint(painter: _SparklinePainter()),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top-left white-framed dark emerald bar chart card
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
                        _MiniBar(height: 18, colors: [Color(0xFF7AF9C9), Color(0xFF16C79A)]),
                        _MiniBar(height: 46, colors: [Color(0xFFF3C867), Color(0xFFD49D35)]),
                        _MiniBar(height: 30, colors: [Color(0xFF2FE4AA), Color(0xFF119F7A)]),
                        _MiniBar(height: 36, colors: [Color(0xFF42E6B2), Color(0xFF15AD83)]),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Front-right crisp white "Your money, your control." card
            Positioned(
              right: 22,
              bottom: 16,
              child: Transform.rotate(
                angle: 0.08,
                child: GestureDetector(
                  onTap: onActionTap,
                  child: Container(
                    width: 148,
                    height: 134,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
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
                          style: GoogleFonts.plusJakartaSans(
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

class _SplitVaultShowcaseSlide extends StatelessWidget {
  final VoidCallback onActionTap;

  const _SplitVaultShowcaseSlide({required this.onActionTap});

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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedGold,
                        ),
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          _AvatarDot(label: 'A', color: Color(0xFF16C79A)),
                          SizedBox(width: 6),
                          _AvatarDot(label: 'H', color: Color(0xFFD4AF6B)),
                          SizedBox(width: 6),
                          _AvatarDot(label: 'Z', color: Color(0xFF60A5FA)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Roommate Group',
                        style: GoogleFonts.inter(
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
                          style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
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

class _SecurityPdfShowcaseSlide extends StatelessWidget {
  final VoidCallback onActionTap;

  const _SecurityPdfShowcaseSlide({required this.onActionTap});

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
                        style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
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

class _MiniBar extends StatelessWidget {
  final double height;
  final List<Color> colors;

  const _MiniBar({required this.height, required this.colors});

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

class _AvatarDot extends StatelessWidget {
  final String label;
  final Color color;

  const _AvatarDot({required this.label, required this.color});

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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF03211B),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
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

    // Subtle wave dot highlights along curve
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
