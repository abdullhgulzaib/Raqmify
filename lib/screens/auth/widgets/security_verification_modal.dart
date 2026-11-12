import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../providers/auth_provider.dart';

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

    // If user has not set a PIN yet, allow action or prompt to set PIN
    if (!auth.hasPin) {
      return true;
    }

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptBiometric();
    });
  }

  void _promptBiometric() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isBiometricEnabled) return;

    final biometricService = BiometricService();
    final canBio = await biometricService.canCheckBiometrics();
    if (!canBio) return;

    final authenticated = await biometricService.authenticate(
      reason: 'Scan fingerprint to authorize action',
    );

    if (authenticated && mounted) {
      Navigator.pop(context, true);
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
      _verify();
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

  void _verify() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.verifyPin(_enteredPin)) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _hasError = true);
      await Future.delayed(const Duration(milliseconds: 400));
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              color: AppColors.borderLight,
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
              color: AppColors.darkInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textMuted,
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
                          ? AppColors.deepEmerald
                          : Colors.transparent,
                  border: Border.all(
                    color: _hasError
                        ? AppColors.errorRed
                        : isFilled
                            ? AppColors.deepEmerald
                            : AppColors.borderLight,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Keypad
          _buildCompactKeypad(),
        ],
      ),
    );
  }

  Widget _buildCompactKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('1'), _buildKey('2'), _buildKey('3')],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('4'), _buildKey('5'), _buildKey('6')],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey('7'), _buildKey('8'), _buildKey('9')],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconButton(
              icon: Icons.fingerprint_rounded,
              color: AppColors.deepEmerald,
              onTap: _promptBiometric,
            ),
            _buildKey('0'),
            _buildIconButton(
              icon: Icons.backspace_outlined,
              color: AppColors.darkInk,
              onTap: _onDeleteTapped,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onDigitTapped(digit),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.outfit(
              fontSize: 22,
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
