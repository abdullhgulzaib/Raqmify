import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/split_provider.dart';
import '../auth/welcome_screen.dart';
import '../auth/widgets/security_verification_modal.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback onNavigateToExpenses;
  final VoidCallback onNavigateToSplit;
  final VoidCallback? onNavigateToSettings;

  const DashboardTab({
    super.key,
    required this.onNavigateToExpenses,
    required this.onNavigateToSplit,
    this.onNavigateToSettings,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isDropdownOpen = false;
  bool _hasUnreadNotifications = true;

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'housing':
      case 'rent':
        return Icons.home_rounded;
      case 'transportation':
      case 'travel':
        return Icons.directions_bus_rounded;
      case 'groceries':
      case 'grocery':
        return Icons.shopping_basket_rounded;
      case 'bills':
      case 'bill':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'health':
      case 'medical':
        return Icons.medical_services_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_creation_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  void _closeDropdown() {
    if (_isDropdownOpen) {
      setState(() => _isDropdownOpen = false);
    }
  }

  void _showNotificationsSheet(BuildContext context) {
    _closeDropdown();
    setState(() => _hasUnreadNotifications = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EAE5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101817),
                    ),
                  ),
                  Text(
                    'All caught up',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16C79A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildNotifTile(
                icon: Icons.shield_rounded,
                title: 'Security Vault Active',
                desc: 'Your 4-Digit PIN & Biometric protection are actively securing transactions.',
                time: 'Just now',
              ),
              const SizedBox(height: 10),
              _buildNotifTile(
                icon: Icons.pie_chart_rounded,
                title: 'Expense Analytics Updated',
                desc: '10-Color coordinated category breakdown is ready for this cycle.',
                time: '2h ago',
              ),
              const SizedBox(height: 10),
              _buildNotifTile(
                icon: Icons.group_work_rounded,
                title: 'SplitVault Status',
                desc: 'All group balances and roommate net debts are synced with cloud ledger.',
                time: '1d ago',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotifTile({
    required IconData icon,
    required String title,
    required String desc,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAE5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0B3D34), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101817),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        color: const Color(0xFF61716D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: const Color(0xFF61716D),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, UserModel? user) {
    _closeDropdown();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EAE5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F1EC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B3D34),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.name ?? 'User',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF101817),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'user@raqmify.app',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF61716D),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2EAE5)),
                ),
                child: Column(
                  children: [
                    _buildProfileInfoRow('Account ID', user?.id ?? 'demo_user_101'),
                    const Divider(height: 18, color: Color(0xFFE2EAE5)),
                    _buildProfileInfoRow('Easypaisa', user?.easypaisa ?? '03001234567'),
                    const Divider(height: 18, color: Color(0xFFE2EAE5)),
                    _buildProfileInfoRow('JazzCash', user?.jazzcash ?? '03001234567'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFF61716D),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF101817),
          ),
        ),
      ],
    );
  }

  void _showHelpSupportSheet(BuildContext context) {
    _closeDropdown();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EAE5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Help & Support',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF101817),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Raqmify personal financial management assistance.',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF61716D),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2EAE5)),
                ),
                child: Column(
                  children: [
                    _buildHelpRow(Icons.mail_outline_rounded, 'Contact Support', 'support@raqmify.app'),
                    const Divider(height: 18, color: Color(0xFFE2EAE5)),
                    _buildHelpRow(Icons.info_outline_rounded, 'App Version', 'Raqmify Mobile v1.0'),
                    const Divider(height: 18, color: Color(0xFFE2EAE5)),
                    _buildHelpRow(Icons.lock_clock_rounded, 'Vault Security', '4-Digit PIN & Biometrics Active'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0B3D34)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF101817)),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF61716D),
          ),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context, AuthProvider auth) {
    _closeDropdown();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Log Out',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF101817),
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your Raqmify vault?',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF61716D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final splitProvider = Provider.of<SplitProvider>(context);

    final isMasked = authProvider.isPrivacyMasked;
    final user = authProvider.currentUser;
    final fullName = user?.name.trim() ?? 'User';
    final firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'User';

    // Roommate summary
    final myDebts = splitProvider.getDebtsForUser(user?.id ?? 'demo_user_101');
    final iAmOwed = myDebts
        .where((d) => d.toUserId == (user?.id ?? 'demo_user_101'))
        .fold(0.0, (sum, d) => sum + d.netAmount);
    final iOwe = myDebts
        .where((d) => d.fromUserId == (user?.id ?? 'demo_user_101'))
        .fold(0.0, (sum, d) => sum + d.netAmount);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 1: Main Scrollable Dashboard Content
            RefreshIndicator(
              color: const Color(0xFF0B3D34),
              onRefresh: () async {
                if (!authProvider.isDemoUser) {
                  await expenseProvider.fetchExpenses();
                  await splitProvider.fetchGroupsAndData();
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Dashboard Header: Raqmify Branding (left) & Actions (right)
                    _buildDashboardHeader(user),
                    const SizedBox(height: 18),

                    // 2. Greeting Section
                    _buildGreetingSection(firstName),
                    const SizedBox(height: 18),

                    // 3. Primary Hero Total Balance Card (Deep Emerald with Eye visibility toggle)
                    _buildTotalBalanceCard(context, authProvider, expenseProvider, isMasked),
                    const SizedBox(height: 18),

                    // 4. SplitVault Roommate Net Status Banner
                    if (iAmOwed > 0 || iOwe > 0)
                      InkWell(
                        onTap: widget.onNavigateToSplit,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.handshake_rounded,
                                  color: AppColors.deepEmerald,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SplitVault: Hostel Room 304',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepEmerald,
                                      ),
                                    ),
                                    Text(
                                      iAmOwed > 0
                                          ? 'Roommates owe you ${CurrencyFormatter.format(iAmOwed, isMasked: isMasked)}'
                                          : 'You owe roommates ${CurrencyFormatter.format(iOwe, isMasked: isMasked)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.darkInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.deepEmerald,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (iAmOwed > 0 || iOwe > 0) const SizedBox(height: 20),

                    // 5. Recent Expenses Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Expenses',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF101817),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToExpenses,
                          child: Text(
                            'See All (${expenseProvider.expenses.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0B3D34),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Recent Transactions List
                    if (expenseProvider.expenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2EAE5)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Color(0xFF61716D),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No expenses added yet',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF101817),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the + button below to record your first transaction.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF61716D),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: expenseProvider.expenses.length > 5
                            ? 5
                            : expenseProvider.expenses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final exp = expenseProvider.expenses[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2EAE5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F8F6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(exp.category),
                                    color: const Color(0xFF0B3D34),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exp.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF101817),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            DateFormat('dd MMM, hh:mm a').format(exp.date),
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: const Color(0xFF61716D),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF7F8F6),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              exp.paymentMethod,
                                              style: GoogleFonts.outfit(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF101817),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(exp.amount, isMasked: isMasked),
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF101817),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Layer 2: Transparent Barrier when dropdown is open
            if (_isDropdownOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeDropdown,
                  child: Container(color: Colors.transparent),
                ),
              ),

            // Layer 3: Compact Account Dropdown (Positioned directly below the avatar button on top-right)
            if (_isDropdownOpen)
              Positioned(
                top: 54,
                right: 20,
                child: _buildCompactAccountDropdown(context, authProvider, user),
              ),
          ],
        ),
      ),
    );
  }

  // 1. Dashboard Header: Raqmify Logo & Wordmark (left) & Actions (right)
  Widget _buildDashboardHeader(UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Side – Raqmify Branding
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/images/raqmify_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'Raqmify',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0B3D34),
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),

        // Right Side – Header Actions (Notification Bell & Profile Avatar Button)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Notification Bell
            InkWell(
              onTap: () => _showNotificationsSheet(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2EAE5)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: Color(0xFF0B3D34),
                    ),
                    if (_hasUnreadNotifications)
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Container(
                          width: 6.5,
                          height: 6.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16C79A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Circular User Profile / Avatar Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isDropdownOpen = !_isDropdownOpen);
              },
              borderRadius: BorderRadius.circular(19),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F1EC), // Soft sage background
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isDropdownOpen
                        ? const Color(0xFF0B3D34)
                        : const Color(0xFFE2EAE5),
                    width: _isDropdownOpen ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0B3D34),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Greeting Section
  Widget _buildGreetingSection(String firstName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salam, $firstName 👋',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101817),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Here's your financial overview.",
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF61716D),
              ),
            ),
          ],
        ),

        // Date/Month Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2EAE5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: Color(0xFF0B3D34),
              ),
              const SizedBox(width: 5),
              Text(
                DateFormat('dd MMM').format(DateTime.now()),
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF101817),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Total Balance Card (Deep Emerald with Eye visibility toggle on right)
  Widget _buildTotalBalanceCard(
    BuildContext context,
    AuthProvider authProvider,
    ExpenseProvider expenseProvider,
    bool isMasked,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3D34),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D34).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL BALANCE',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16C79A),
                ),
              ),
              InkWell(
                onTap: () async {
                  if (isMasked && authProvider.hasPin) {
                    final verified = await SecurityVerificationModal.verify(
                      context,
                      title: 'Unlock Privacy Vault',
                      subtitle: 'Enter 4-Digit PIN or touch Fingerprint to reveal balance',
                    );
                    if (verified) {
                      authProvider.togglePrivacyMask();
                    }
                  } else {
                    authProvider.togglePrivacyMask();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMasked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 18,
                    color: isMasked ? const Color(0xFFD4AF6B) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Balance Amount
          Text(
            isMasked
                ? 'Rs ••••••••'
                : CurrencyFormatter.format(expenseProvider.currentMonthTotal, isMasked: false),
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),

          // Divider
          Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
          const SizedBox(height: 16),

          // Sub-metrics: Today's Spend & Daily Average
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S SPEND",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMasked
                          ? '••••'
                          : CurrencyFormatter.format(expenseProvider.todaySpend, isMasked: false),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4AF6B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DAILY AVERAGE",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMasked
                          ? '••••/day'
                          : '${CurrencyFormatter.format(expenseProvider.dynamicDailyAverage, isMasked: false)}/day',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Compact Account Dropdown (220px, Right-aligned below profile button)
  Widget _buildCompactAccountDropdown(
    BuildContext context,
    AuthProvider authProvider,
    UserModel? user,
  ) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAE5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A. Compact Account Information Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7F1EC),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B3D34),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF101817),
                          ),
                        ),
                        Text(
                          user?.email ?? 'user@raqmify.app',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            color: const Color(0xFF61716D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            const Divider(height: 10, thickness: 1, color: Color(0xFFE2EAE5)),
            const SizedBox(height: 2),

            // B. Vertical Menu Column (6 items)
            _buildDropdownItem(
              icon: Icons.person_outline_rounded,
              label: 'My Profile',
              onTap: () => _showProfileSheet(context, user),
            ),
            _buildDropdownItem(
              icon: Icons.settings_outlined,
              label: 'Account Settings',
              onTap: () {
                widget.onNavigateToSettings?.call();
              },
            ),
            _buildDropdownItem(
              icon: Icons.shield_outlined,
              label: 'Privacy Vault',
              onTap: () async {
                if (authProvider.isPrivacyMasked && authProvider.hasPin) {
                  final verified = await SecurityVerificationModal.verify(
                    context,
                    title: 'Unlock Privacy Vault',
                    subtitle: 'Enter 4-Digit PIN or touch Fingerprint to reveal balance',
                  );
                  if (verified) {
                    authProvider.togglePrivacyMask();
                  }
                } else {
                  authProvider.togglePrivacyMask();
                }
              },
            ),
            _buildDropdownItem(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => _showNotificationsSheet(context),
            ),
            _buildDropdownItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () => _showHelpSupportSheet(context),
            ),
            _buildDropdownItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              iconColor: const Color(0xFFEF4444),
              textColor: const Color(0xFFEF4444),
              onTap: () => _handleLogout(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF0B3D34),
    Color textColor = const Color(0xFF101817),
  }) {
    return InkWell(
      onTap: () {
        _closeDropdown();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16.5, color: iconColor),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
