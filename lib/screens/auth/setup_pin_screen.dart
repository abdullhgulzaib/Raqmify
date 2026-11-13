import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import 'widgets/emerald_wave_header.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen>
    with SingleTickerProviderStateMixin {
  int _step = 1; // 1: Enter PIN, 2: Confirm PIN
  String _firstPin = '';
  String _confirmPin = '';
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasBiometricHardware = false;
  bool _enableBiometric = true;
  bool _isSaving = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final bioService = BiometricService();
    final canBio = await bioService.canCheckBiometrics();
    if (mounted) {
      setState(() => _hasBiometricHardware = canBio);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String get _currentPin => _step == 1 ? _firstPin : _confirmPin;

  void _onDigitTapped(String digit) {
    if (_isSaving) return;
    if (_currentPin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      if (_step == 1) {
        _firstPin += digit;
      } else {
        _confirmPin += digit;
      }
      _hasError = false;
      _errorMessage = '';
    });

    if (_step == 1 && _firstPin.length == 4) {
      // Advance to confirmation step after slight delay
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          _step = 2;
          _confirmPin = '';
        });
      });
    } else if (_step == 2 && _confirmPin.length == 4) {
      _validateAndSave();
    }
  }

  void _onDeleteTapped() {
    if (_isSaving || _currentPin.isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      if (_step == 1) {
        _firstPin = _firstPin.substring(0, _firstPin.length - 1);
      } else {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _onResetToStepOne() {
    setState(() {
      _step = 1;
      _firstPin = '';
      _confirmPin = '';
      _hasError = false;
      _errorMessage = '';
    });
  }

  Future<void> _validateAndSave() async {
    if (_firstPin != _confirmPin) {
      await HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs did not match. Please try again.';
      });
      _shakeController.forward(from: 0.0);

      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      _onResetToStepOne();
      return;
    }

    setState(() => _isSaving = true);
    await HapticFeedback.mediumImpact();

    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.setVaultPin(_firstPin);
    if (_hasBiometricHardware) {
      await auth.setBiometricEnabled(_enableBiometric);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('4-Digit Security PIN successfully activated!'),
          ],
        ),
        backgroundColor: AppColors.deepEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Forced screen: Pop is disabled until 4-digit PIN is configured
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                  heightFactor: 0.42,
                  highRightWave: false,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Top Brand & Header Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Column(
                        children: [
                          const RaqmifyBrandLogo(size: 58, showGlow: true),
                          const SizedBox(height: 12),
                          Text(
                            _step == 1
                                ? 'Set 4-Digit Security PIN'
                                : 'Confirm Your Security PIN',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _step == 1
                                ? 'Create your 4-digit PIN to secure transactions & authorize expenses.'
                                : 'Re-enter your 4-digit PIN to confirm accuracy.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Step Indicator Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _step == 1 ? 'Step 1 of 2: Create PIN' : 'Step 2 of 2: Confirm PIN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEmerald,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 4 Dots with Shake Animation on mismatch
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
                          final isFilled = index < _currentPin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
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
                                        : AppColors.borderLight,
                                width: 2.2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Error Message
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.errorRed,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Biometric Option Card (if device has biometric hardware)
                    if (_hasBiometricHardware && _step == 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.fingerprint_rounded,
                                color: AppColors.deepEmerald,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Enable Fingerprint Sign-in',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkInk,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: _enableBiometric,
                                activeTrackColor: AppColors.deepEmerald,
                                onChanged: (v) => setState(() => _enableBiometric = v),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Keypad
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildKeypad(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            _step == 2
                ? InkWell(
                    onTap: _onResetToStepOne,
                    borderRadius: BorderRadius.circular(36),
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: Center(
                        child: Text(
                          'Back',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepEmerald,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 68, height: 68),
            _buildKey('0'),
            InkWell(
              onTap: _onDeleteTapped,
              borderRadius: BorderRadius.circular(36),
              child: const SizedBox(
                width: 68,
                height: 68,
                child: Center(
                  child: Icon(
                    Icons.backspace_outlined,
                    color: AppColors.darkInk,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onDigitTapped(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.darkInk,
            ),
          ),
        ),
      ),
    );
  }
}
