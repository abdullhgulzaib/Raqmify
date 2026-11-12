import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/pdf_generator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/split_provider.dart';
import '../auth/login_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  void _showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set 4-Digit Privacy PIN',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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
              decoration: const InputDecoration(
                hintText: '••••',
                prefixIcon: Icon(Icons.lock_rounded, color: AppColors.deepEmerald),
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
      ),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Settings & Vault',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkInk,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderLight),
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
                            color: AppColors.darkInk,
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
                            color: AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hostel Resident • PKR',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepEmerald,
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
                color: AppColors.darkInk,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.pin_rounded, color: AppColors.deepEmerald),
                    title: Text(
                      '4-Digit Security PIN',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      authProvider.hasPrivacyPin ? 'PIN is active (${authProvider.vaultPin != null ? '••••' : ''})' : 'Not set (tap to set)',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _showSetPinDialog(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.deepEmerald),
                    title: Text(
                      'Biometric / Fingerprint Unlock',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Unlock app with fingerprint sensor',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                    value: authProvider.isBiometricEnabled,
                    activeThumbColor: AppColors.deepEmerald,
                    onChanged: (val) => authProvider.setBiometricEnabled(val),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_rounded, color: AppColors.deepEmerald),
                    title: Text(
                      'Privacy Mode (Eye)',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
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

            // 3. Data & Export Lifecycle Section (Module 5)
            Text(
              'Data Lifecycle & Export',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkInk,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.deepEmerald),
                    title: Text(
                      'Generate PDF Statement',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Formatted itemized statement with official header',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.download_rounded, color: AppColors.deepEmerald),
                    onTap: () => _exportPdf(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Smart Retention Policy Notice Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
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
                            color: AppColors.deepEmerald,
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
                color: AppColors.darkInk,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightEmerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.deepEmerald),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raqmify Mobile v1.0.0',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
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
