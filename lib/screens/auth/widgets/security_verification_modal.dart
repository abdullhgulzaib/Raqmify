import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/services/biometric_service.dart';
import '../../../providers/auth_provider.dart';
import '../setup_pin_screen.dart';

class SecurityVerificationModal extends StatefulWidget {
  final String title;
  final String subtitle;

  const SecurityVerificationModal({
    super.key,
    this.title = 'Security Verification',
    this.subtitle = 'Enter your 4-Digit PIN to authorize',
  });

  static Future<bool> verify(
    BuildContext context, {
    String title = 'Security Verification',
    String subtitle = 'Enter your 4-Digit PIN or touch Fingerprint to authorize',
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // If user has not set a PIN yet, force PIN setup flow (S3)
    if (!auth.hasPin) {
      final setupSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SetupPinScreen()),
      );
      if (setupSuccess != true) {
        return false;
      }
    }

    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SecurityVerificationModal(title: title, subtitle: subtitle),
    );

    return result ?? false;
  }

  @override
  State<SecurityVerificationModal> createState() => _SecurityVerificationModalState();
}

class _SecurityVerificationModalState extends State<SecurityVerificationModal> {
  String _enteredPin = '';
  bool _hasError = false;
  String? _statusMessage;
  bool _isLockedOut = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockoutAndPromptBiometric();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLockedOut = true;
      _statusMessage = 'Cooldown active: try again in ${seconds}s';
    });

    int remaining = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        if (!mounted) return;
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.checkLockout();
        if (mounted) {
          setState(() {
            _isLockedOut = false;
            _statusMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = 'Cooldown active: try again in ${remaining}s';
          });
        }
      }
    });
  }

  void _checkLockoutAndPromptBiometric() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final remaining = await auth.checkLockout();
    if (remaining > 0) {
      _startCountdown(remaining);
      return;
    }

    if (!auth.isBiometricEnabled) return;

    final biometricService = BiometricService();
    final res = await biometricService.authenticateDetailed(
      reason: 'Scan fingerprint to authorize action',
    );

    if (res.success && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _onDigitTapped(String digit) {
    if (_isLockedOut || _enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin += digit;
      _hasError = false;
      _statusMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verify();
    }
  }

  void _onDeleteTapped() {
    if (_isLockedOut || _enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  void _verify() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.verifyPin(_enteredPin);

    if (!mounted) return;

    if (result.isSuccess) {
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      await HapticFeedback.heavyImpact();
      if (result.isLockedOut) {
        _startCountdown(result.lockoutSeconds);
      } else {
        setState(() {
          _hasError = true;
          _statusMessage = result.errorMessage ?? 'Incorrect PIN';
          _isLockedOut = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _hasError = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.offWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _statusMessage ?? widget.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: _hasError ? AppColors.errorRed : (isDark ? Colors.grey[400] : AppColors.textMuted),
              fontWeight: _hasError ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 24),

          // 4 Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
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
          const SizedBox(height: 24),

          // Keypad
          _buildCompactKeypad(isDark),
        ],
      ),
    );
  }

  Widget _buildCompactKeypad(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('1', isDark), _buildKey('2', isDark), _buildKey('3', isDark)],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('4', isDark), _buildKey('5', isDark), _buildKey('6', isDark)],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('7', isDark), _buildKey('8', isDark), _buildKey('9', isDark)],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconButton(
              icon: AppIcons.fingerprint,
              color: isDark ? AppColors.teal : AppColors.deepEmerald,
              onTap: _checkLockoutAndPromptBiometric,
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
    return InkWell(
      onTap: () => _onDigitTapped(digit),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.darkInk,
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
      borderRadius: BorderRadius.circular(35),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}
