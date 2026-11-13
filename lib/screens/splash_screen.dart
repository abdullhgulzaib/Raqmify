import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'auth/quick_pin_unlock_screen.dart';
import 'auth/setup_pin_screen.dart';
import 'auth/welcome_screen.dart';
import 'auth/widgets/emerald_wave_header.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1850),
    );

    _logoController.forward();
    _progressController.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isInitialized) {
      await authProvider.init();
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final Widget destination;

    if (authProvider.isAuthenticated) {
      if (!authProvider.hasPin) {
        destination = const SetupPinScreen();
      } else {
        destination = const QuickPinUnlockScreen();
      }
    } else {
      destination = const WelcomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF03241D),
                Color(0xFF083C31),
                Color(0xFF052820),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Ambient subtle emerald halo behind the mark
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.teal.withValues(alpha: 0.16),
                        AppColors.teal.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const RaqmifyBrandLogo(size: 112, showGlow: true),
                                  const SizedBox(height: 22),
                                  Text(
                                    'Raqmify',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.9,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Your money, your control.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.72),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 42),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 140,
                                    height: 4,
                                    child: AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (context, _) {
                                        final t = Curves.easeInOutCubic.transform(
                                          _progressController.value,
                                        );
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(99),
                                          child: Stack(
                                            children: [
                                              Container(
                                                color: Colors.white.withValues(alpha: 0.12),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor: t.clamp(0.08, 1.0),
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        AppColors.teal,
                                                        AppColors.mutedGold,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Securing your vault...',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.56),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
