import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';

class QuickPinUnlockScreen extends StatefulWidget {
  const QuickPinUnlockScreen({super.key});

  @override
  State<QuickPinUnlockScreen> createState() => _QuickPinUnlockScreenState();
}

class _QuickPinUnlockScreenState extends State<QuickPinUnlockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Auto-prompt Fingerprint / Biometric if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptBiometric();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _checkAndPromptBiometric() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isBiometricEnabled) return;

    final biometricService = BiometricService();
    final canBio = await biometricService.canCheckBiometrics();
    if (!canBio) return;

    final authenticated = await biometricService.authenticate(
      reason: 'Scan your fingerprint to unlock Raqmify',
    );

    if (authenticated && mounted) {
      _onUnlockSuccess();
    }
  }

  void _onDigitTapped(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin += digit;
      _hasError = false;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeleteTapped() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  void _verifyPin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final correct = auth.verifyPin(_enteredPin);

    if (correct) {
      HapticFeedback.mediumImpact();
      _onUnlockSuccess();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _hasError = true);
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect 4-Digit PIN. Please try again.'),
          backgroundColor: AppColors.errorRed,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _hasError = false;
        });
      }
    }
  }

  void _onUnlockSuccess() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.unlockApp();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _handleSwitchAccount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.user?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Brand Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.deepEmerald,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepEmerald.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                'Welcome Back',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter 4-Digit PIN or touch Fingerprint',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 36),

              // 4 PIN Dots with shake animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_hasError ? _shakeAnimation.value : 0, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? AppColors.errorRed
                            : isFilled
                                ? AppColors.deepEmerald
                                : Colors.transparent,
                        border: Border.all(
                          color: _hasError
                              ? AppColors.errorRed
                              : isFilled
                                  ? AppColors.deepEmerald
                                  : AppColors.borderLight.withValues(alpha: 0.9),
                          width: 2.5,
                        ),
                        boxShadow: isFilled && !_hasError
                            ? [
                                BoxShadow(
                                  color: AppColors.deepEmerald.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),

              // Numeric Keypad
              _buildKeypad(),

              const SizedBox(height: 24),

              // Switch Account / Logout
              GestureDetector(
                onTap: _handleSwitchAccount,
                child: Text(
                  'Switch Account / Sign Out',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Fingerprint Trigger Key
              _buildIconButton(
                icon: Icons.fingerprint_rounded,
                color: AppColors.deepEmerald,
                onTap: _checkAndPromptBiometric,
              ),
              _buildKey('0'),
              // Backspace Key
              _buildIconButton(
                icon: Icons.backspace_outlined,
                color: AppColors.darkInk,
                onTap: _onDeleteTapped,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onDigitTapped(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.darkInk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}
