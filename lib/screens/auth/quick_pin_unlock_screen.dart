import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/split_provider.dart';
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
  String? _errorMessage;
  int _lockoutSeconds = 0;
  Timer? _countdownTimer;

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

    _checkInitialLockout();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptBiometric();
    });
  }

  void _checkInitialLockout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final remaining = await auth.checkLockout();
    if (remaining > 0) {
      _startLockoutCountdown(remaining);
    }
  }

  void _startLockoutCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _lockoutSeconds = seconds;
      _errorMessage = 'Too many failed attempts. Try again in ${_lockoutSeconds}s';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.checkLockout();
        if (mounted) {
          setState(() {
            _lockoutSeconds = 0;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _lockoutSeconds--;
            _errorMessage = 'Cooldown active. Try again in ${_lockoutSeconds}s';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkAndPromptBiometric() async {
    if (_lockoutSeconds > 0) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isBiometricEnabled) return;

    final biometricService = BiometricService();
    final res = await biometricService.authenticateDetailed(
      reason: 'Scan fingerprint or enter device credential to unlock Raqmify',
    );

    if (res.success && mounted) {
      _onUnlockSuccess();
    }
  }

  void _onDigitTapped(String digit) {
    if (_lockoutSeconds > 0 || _enteredPin.length >= 4) return;
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
    if (_lockoutSeconds > 0 || _enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  void _verifyPin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.verifyPin(_enteredPin);

    if (!mounted) return;

    if (result.isSuccess) {
      await HapticFeedback.mediumImpact();
      _onUnlockSuccess();
    } else {
      await HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _errorMessage = result.errorMessage;
      });
      _shakeController.forward(from: 0.0);

      if (!mounted) return;
      if (result.shouldLogout) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account locked due to 10 failed attempts. Please sign in with password.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      if (result.isLockedOut) {
        _startLockoutCountdown(result.lockoutSeconds);
      }

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
    final expProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    expProvider.clearData();
    splitProvider.clearData();
    notifProvider.clearData();
    await notifProvider.setActiveUser(null);
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
    final userName = auth.currentUser?.name ?? 'User';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.offWhite,
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
                  color: isDark ? AppColors.darkCard : AppColors.deepEmerald,
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepEmerald.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(AppIcons.lock, color: isDark ? AppColors.teal : Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                'Welcome Back',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.darkInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Enter 4-Digit PIN or touch Fingerprint',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _hasError || _lockoutSeconds > 0
                      ? AppColors.errorRed
                      : (isDark ? Colors.grey[400] : AppColors.textMuted),
                  fontWeight: _hasError || _lockoutSeconds > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),

              const SizedBox(height: 36),

              // 4 PIN Dots with shake animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
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
                                ? (isDark ? AppColors.teal : AppColors.deepEmerald)
                                : Colors.transparent,
                        border: Border.all(
                          color: _hasError
                              ? AppColors.errorRed
                              : isFilled
                                  ? (isDark ? AppColors.teal : AppColors.deepEmerald)
                                  : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),

              // Numeric Keypad
              _buildKeypad(isDark),

              const SizedBox(height: 24),

              // Switch Account Option
              TextButton(
                onPressed: _handleSwitchAccount,
                child: Text(
                  'Switch Account / Log Out',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.teal : AppColors.deepEmerald,
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

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('1', isDark), _buildKey('2', isDark), _buildKey('3', isDark)],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('4', isDark), _buildKey('5', isDark), _buildKey('6', isDark)],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('7', isDark), _buildKey('8', isDark), _buildKey('9', isDark)],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconButton(
              icon: AppIcons.fingerprint,
              color: isDark ? AppColors.teal : AppColors.deepEmerald,
              onTap: _checkAndPromptBiometric,
            ),
            _buildKey('0', isDark),
            _buildIconButton(
              icon: Icons.backspace_outlined,
              color: isDark ? Colors.white70 : AppColors.darkInk,
              onTap: _onDeleteTapped,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit, bool isDark) {
    final disabled = _lockoutSeconds > 0;
    return InkWell(
      onTap: disabled ? null : () => _onDigitTapped(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled
              ? (isDark ? Colors.grey[900] : Colors.grey[200])
              : (isDark ? AppColors.darkCard : Colors.white),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            if (!disabled)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: disabled
                  ? Colors.grey
                  : (isDark ? Colors.white : AppColors.darkInk),
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
      onTap: _lockoutSeconds > 0 ? null : onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(icon, color: _lockoutSeconds > 0 ? Colors.grey : color, size: 28),
        ),
      ),
    );
  }
}
