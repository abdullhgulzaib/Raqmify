import 'package:flutter/foundation.dart';
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
import 'widgets/welcome_slides.dart';

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
    if (!kDebugMode) return;
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
                                        HeroControlDeckSlide(
                                          onActionTap: _advanceSlideOrLogin,
                                        ),
                                        SplitVaultShowcaseSlide(
                                          onActionTap: _advanceSlideOrLogin,
                                        ),
                                        SecurityPdfShowcaseSlide(
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
                                    if (kDebugMode) ...[
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
                                          style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
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
