import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/split_provider.dart';
import 'login_screen.dart';
import 'setup_pin_screen.dart';
import 'widgets/emerald_wave_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in your name and email address.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please check and try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.register(name, email, password);

    if (!mounted) return;
    if (result.isSuccess) {
      // Clear demo data and fetch fresh user data from database
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final splitProvider = Provider.of<SplitProvider>(context, listen: false);
      expenseProvider.clearData();
      splitProvider.clearData();
      await expenseProvider.fetchExpenses();
      await splitProvider.fetchGroupsAndData();

      if (!mounted) return;
      // Force user to setup 4-digit PIN right after registration (S3)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SetupPinScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Registration failed'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canPop = Navigator.canPop(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = (constraints.maxHeight * 0.27).clamp(185.0, 224.0);
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: EmeraldWaveBackdrop(
                              heightFactor: 0.96,
                              highRightWave: false,
                            ),
                          ),
                          SafeArea(
                            bottom: false,
                            child: Stack(
                              children: [
                                if (canPop)
                                  Positioned(
                                    top: 6,
                                    left: 10,
                                    child: IconButton(
                                      onPressed: () => Navigator.maybePop(context),
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      tooltip: 'Back',
                                    ),
                                  ),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const RaqmifyBrandLogo(size: 50, showGlow: true),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Create Account',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Your money, your control.',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha: 0.78),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 14, 26, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Full Name',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkInk,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Abdullah Khan',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Email Address',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkInk,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'e.g. abdullah@example.com',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Password (min 6 characters)',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkInk,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Create a password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.textMuted,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Confirm Password',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkInk,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(
                                Icons.lock_reset_outlined,
                                color: AppColors.textMuted,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06342A),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.outfit(color: AppColors.textMuted),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Log in',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.deepEmerald,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
