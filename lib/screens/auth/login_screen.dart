import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/split_provider.dart';
import '../main_navigation_screen.dart';
import 'register_screen.dart';
import 'setup_pin_screen.dart';
import 'widgets/emerald_wave_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      // Clear sample data and fetch actual data from database
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final splitProvider = Provider.of<SplitProvider>(context, listen: false);
      expenseProvider.clearData();
      splitProvider.clearData();
      await expenseProvider.fetchExpenses();
      await splitProvider.fetchGroupsAndData();

      if (!mounted) return;
      final destination = auth.hasPin
          ? const MainNavigationScreen()
          : const SetupPinScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _handleDemoLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);

    await auth.demoLogin();

    // Populate with demo living suite for offline testing
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
            final headerHeight = (constraints.maxHeight * 0.33).clamp(215.0, 268.0);
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
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const RaqmifyBrandLogo(size: 62, showGlow: true),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Welcome Back',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sign in to your Raqmify vault',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
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
                      padding: const EdgeInsets.fromLTRB(26, 20, 26, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                              hintText: 'Enter your email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Text(
                            'Password',
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
                              hintText: 'Enter your password',
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
                          const SizedBox(height: 28),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
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
                                      'Sign In',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _handleDemoLogin,
                              icon: const Icon(Icons.bolt, color: AppColors.mutedGold),
                              label: const Text('Quick Demo Mode (Hostel Room 304)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.deepEmerald,
                                side: const BorderSide(
                                  color: AppColors.mutedGold,
                                  width: 1.2,
                                ),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.outfit(color: AppColors.textMuted),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Create Account',
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
