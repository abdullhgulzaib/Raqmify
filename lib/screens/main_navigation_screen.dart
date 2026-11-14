import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/split_provider.dart';
import 'auth/widgets/security_verification_modal.dart';
import 'dashboard/dashboard_tab.dart';
import 'dashboard/widgets/add_expense_bottom_sheet.dart';
import 'expenses/expenses_tab.dart';
import 'analytics/analytics_tab.dart';
import 'split_vault/split_vault_tab.dart';
import 'split_vault/widgets/create_split_expense_bottom_sheet.dart';
import 'settings/settings_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _splitVaultPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated && !auth.isDemoUser) {
        Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
        Provider.of<SplitProvider>(context, listen: false).fetchGroupsAndData(
          currentUserId: auth.currentUser?.id,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSplitVaultPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated && !auth.isDemoUser) {
        Provider.of<SplitProvider>(context, listen: false).fetchGroupsAndData(
          silent: true,
          currentUserId: auth.currentUser?.id,
        );
      }
      if (_currentIndex == 3) {
        _startSplitVaultPolling();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopSplitVaultPolling();
    }
  }

  void _startSplitVaultPolling() {
    _stopSplitVaultPolling();
    _splitVaultPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final splitProvider = Provider.of<SplitProvider>(context, listen: false);
      if (auth.isAuthenticated && !auth.isDemoUser && !splitProvider.isLoading) {
        splitProvider.fetchGroupsAndData(
          silent: true,
          currentUserId: auth.currentUser?.id,
        );
      }
    });
  }

  void _stopSplitVaultPolling() {
    _splitVaultPollTimer?.cancel();
    _splitVaultPollTimer = null;
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (index == 1) {
      // Switched to Expenses tab: refresh personal expenses
      if (auth.isAuthenticated && !auth.isDemoUser) {
        Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
      }
      _stopSplitVaultPolling();
    } else if (index == 3) {
      // Switched to SplitVault tab: fetch immediately and start 30s polling
      if (auth.isAuthenticated && !auth.isDemoUser) {
        final splitProvider = Provider.of<SplitProvider>(context, listen: false);
        if (!splitProvider.isLoading) {
          splitProvider.fetchGroupsAndData(
            silent: true,
            currentUserId: auth.currentUser?.id,
          );
        }
      }
      _startSplitVaultPolling();
    } else {
      _stopSplitVaultPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardTab(
        onNavigateToExpenses: () => setState(() => _currentIndex = 1),
        onNavigateToSplit: () => setState(() => _currentIndex = 3),
        onNavigateToSettings: () => setState(() => _currentIndex = 4),
      ),
      const ExpensesTab(),
      const AnalyticsTab(),
      const SplitVaultTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Decoupled Context-Aware Floating Action Button on Bottom-Right
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Restored Standard Clean White Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.deepEmerald,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_work_rounded),
              label: 'SplitVault',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // For SplitVaultTab (index 3), show dedicated single "Split Expense" extended FAB with split icon.
    // There is no separate or overlapping + button.
    if (_currentIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await HapticFeedback.lightImpact();
          if (!mounted) return;
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isPrivacyMasked && authProvider.hasPin) {
            final verified = await SecurityVerificationModal.verify(
              context,
              title: 'Authorize Split Bill',
              subtitle: 'Scan fingerprint or enter PIN to continue',
            );
            if (!verified || !mounted) return;
            await authProvider.togglePrivacyMask(force: true);
          }
          if (!mounted) return;
          await CreateSplitExpenseBottomSheet.show(context);
        },
        backgroundColor: AppColors.deepEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.call_split_rounded),
        label: Text(
          'Split Expense',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      );
    }
    return GestureDetector(
      onTap: () async {
        await HapticFeedback.lightImpact();

        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // If Privacy Vault is locked/masked, verify once to unlock
        if (authProvider.isPrivacyMasked && authProvider.hasPin) {
          final verified = await SecurityVerificationModal.verify(
            context,
            title: 'Authorize New Expense',
            subtitle: 'Scan fingerprint or enter PIN to continue',
          );
          if (!verified || !mounted) return;
          // Unlock privacy vault so subsequent expense additions don't prompt PIN repeatedly
          await authProvider.togglePrivacyMask(force: true);
        }

        if (!mounted) return;
        await AddExpenseBottomSheet.show(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0B3D34),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B3D34).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.add_rounded, // Always + icon as requested
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
