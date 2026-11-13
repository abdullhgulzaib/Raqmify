// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/pdf_generator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/split_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  void _showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.darkInk;
        final inputBg = isDark ? const Color(0xFF24322F) : AppColors.surfaceSubtle;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Set 4-Digit Privacy PIN',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a 4-digit PIN to secure your sensitive balance and hostel debt calculations.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: textColor, letterSpacing: 8, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '••••',
                  prefixIcon: const Icon(AppIcons.lock, color: AppColors.deepEmerald),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final pin = pinController.text.trim();
                if (pin.length == 4) {
                  Provider.of<AuthProvider>(context, listen: false).setPrivacyPin(pin);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy PIN updated successfully!'),
                      backgroundColor: AppColors.deepEmerald,
                    ),
                  );
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        );
      },
    );
  }

  void _exportPdf(BuildContext context) async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Generating PDF Statement...', style: GoogleFonts.outfit()),
          ],
        ),
        backgroundColor: AppColors.deepEmerald,
        duration: const Duration(seconds: 2),
      ),
    );

    await PdfStatementGenerator.printOrShareStatement(
      expenses: expenseProvider.expenses,
      userName: authProvider.currentUser?.name ?? 'Rana Abdullah',
      userEmail: authProvider.currentUser?.email ?? 'rana@hostel.edu.pk',
      periodName: DateFormat('MMMM yyyy').format(DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final cardBg = isDark ? const Color(0xFF1E2826) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkInk;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderLight;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B19) : AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Settings & Vault',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.deepEmerald,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'R',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Rana Abdullah',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          user?.email ?? 'rana@hostel.edu.pk',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A3831) : AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hostel Resident • PKR',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Privacy & Security Section
            Text(
              'Security & Privacy Vault',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(AppIcons.lock, color: AppColors.deepEmerald),
                    title: Text(
                      '4-Digit Security PIN',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    subtitle: Text(
                      authProvider.hasPin ? 'PIN is active (••••)' : 'Not set (tap to set)',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _showSetPinDialog(context),
                  ),
                  Divider(height: 1, indent: 56, color: borderColor),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.deepEmerald),
                    title: Text(
                      'Biometric / Fingerprint Unlock',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    subtitle: Text(
                      'Unlock app with fingerprint sensor or device passcode',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                    value: authProvider.isBiometricEnabled,
                    activeThumbColor: AppColors.deepEmerald,
                    onChanged: (val) => authProvider.setBiometricEnabled(val),
                  ),
                  Divider(height: 1, indent: 56, color: borderColor),
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_rounded, color: AppColors.deepEmerald),
                    title: Text(
                      'Privacy Mode (Eye)',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    subtitle: Text(
                      'Hide balances across all screens',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                    value: authProvider.isPrivacyMasked,
                    activeThumbColor: AppColors.deepEmerald,
                    onChanged: (_) => authProvider.togglePrivacyMask(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appearance & Theme Mode Section (U3)
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: Text('System Default', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                            subtitle: Text('Follow operating system setting', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            value: ThemeMode.system,
                            groupValue: themeProvider.themeMode,
                            activeColor: AppColors.teal,
                            onChanged: (mode) => themeProvider.setThemeMode(mode!),
                          ),
                          Divider(height: 1, indent: 56, color: borderColor),
                          RadioListTile<ThemeMode>(
                            title: Text('Light Mode', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                            subtitle: Text('Crisp Off-white & Emerald', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            value: ThemeMode.light,
                            groupValue: themeProvider.themeMode,
                            activeColor: AppColors.deepEmerald,
                            onChanged: (mode) => themeProvider.setThemeMode(mode!),
                          ),
                          Divider(height: 1, indent: 56, color: borderColor),
                          RadioListTile<ThemeMode>(
                            title: Text('Dark Mode', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                            subtitle: Text('Near-black (#101817) & Teal', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                            value: ThemeMode.dark,
                            groupValue: themeProvider.themeMode,
                            activeColor: AppColors.teal,
                            onChanged: (mode) => themeProvider.setThemeMode(mode!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // 3. Data & Export Lifecycle Section
            Text(
              'Data Lifecycle & Export',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.deepEmerald),
                title: Text(
                  'Generate PDF Statement',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  'Formatted itemized statement with official header',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.download_rounded, color: AppColors.deepEmerald),
                onTap: () => _exportPdf(context),
              ),
            ),
            const SizedBox(height: 14),

            // Smart Retention Policy Notice Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162B24) : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.deepEmerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '60-Day Smart Retention Policy',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'As specified in the system design, detailed daily transactions are archived after 60 days to optimize local storage and privacy. Generate monthly PDF statements for permanent recordkeeping.',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. About App
            Text(
              'About Application',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A3831) : AppColors.lightEmerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(AppIcons.wallet, color: AppColors.deepEmerald),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raqmify Mobile v1.0.0',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                          ),
                          Text(
                            '"Your money, your control."',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Built for Mobile Computing Lab Final Evaluation.\nIncludes 4-Digit Privacy Vault, Dynamic Daily Averages, Pairwise Debt Simplification, Single TID Batch Settlement, and Local PDF Statement Export.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.outfit(color: AppColors.errorRed, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  Provider.of<ExpenseProvider>(context, listen: false).clearData();
                  Provider.of<SplitProvider>(context, listen: false).clearData();
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
