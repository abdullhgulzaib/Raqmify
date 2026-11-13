import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/services/retention_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/split_provider.dart';
import 'widgets/add_expense_bottom_sheet.dart';
import 'widgets/dashboard_balance_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_split_summary_card.dart';
import 'widgets/retention_alert_banner.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback onNavigateToExpenses;
  final VoidCallback onNavigateToSplit;
  final VoidCallback onNavigateToSettings;

  const DashboardTab({
    super.key,
    required this.onNavigateToExpenses,
    required this.onNavigateToSplit,
    required this.onNavigateToSettings,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  RetentionStatus? _retentionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final notif = Provider.of<NotificationProvider>(context, listen: false);
      if (auth.currentUser != null) {
        notif.setActiveUser(auth.currentUser!.id);
      }
      _checkRetention();
    });
  }

  void _checkRetention() async {
    final exp = Provider.of<ExpenseProvider>(context, listen: false);
    final status = await RetentionService().checkCleanupStatus(exp.expenses);
    if (mounted) {
      setState(() => _retentionStatus = status);
    }
  }

  void _openAddExpenseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final splitProvider = Provider.of<SplitProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = auth.currentUser;
    final currentUserId = user?.id ?? '';
    final isMasked = auth.isPrivacyMasked;

    final amountYoureOwed = splitProvider.getAmountYoureOwed(currentUserId);
    final amountYouOwe = splitProvider.getAmountYouOwe(currentUserId);

    final recentExpenses = expenseProvider.expenses.take(5).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.offWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.deepEmerald,
          onRefresh: () async {
            if (kDebugMode && auth.isDemoUser) {
              // In debug demo mode, don't overwrite mock state
            } else {
              await expenseProvider.fetchExpenses(refresh: true);
              await splitProvider.fetchGroupsAndData();
              await notifProvider.fetchNotifications();
            }
            _checkRetention();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100), // U7: Bottom padding >= 88 dp for FAB
            children: [
              // 1. Header (Profile, Notification Bell with real count, Greeting, Date)
              DashboardHeader(
                user: user,
                hasUnreadNotifications: notifProvider.hasUnread,
                unreadCount: notifProvider.unreadCount,
                onProfileTap: widget.onNavigateToSettings,
              ),
              const SizedBox(height: 20),

              // 2. 60-Day Data Pruning Alert Banner (F2)
              if (_retentionStatus != null && _retentionStatus!.isApproachingPrune)
                RetentionAlertBanner(
                  status: _retentionStatus!,
                  expenses: expenseProvider.expenses,
                  userName: user?.name ?? 'User',
                  userEmail: user?.email ?? '',
                  onDismiss: () async {
                    await RetentionService().dismissRetentionNotice();
                    if (mounted) setState(() => _retentionStatus = null);
                  },
                ),

              // 3. Main Total Balance & Daily Average Card (Q2, U3)
              DashboardBalanceCard(
                monthTotal: expenseProvider.currentMonthTotal,
                dynamicDailyAvg: expenseProvider.dynamicDailyAverage,
                isPrivacyMasked: isMasked,
                onToggleMask: () => auth.togglePrivacyMask(force: true),
                onAddExpense: () => _openAddExpenseModal(context),
                onSplitBill: widget.onNavigateToSplit,
                onAnalytics: widget.onNavigateToExpenses,
              ),
              const SizedBox(height: 18),

              // 4. SplitVault Summary Card (S8)
              DashboardSplitSummaryCard(
                amountYoureOwed: amountYoureOwed,
                amountYouOwe: amountYouOwe,
                isMasked: isMasked,
                onViewVault: widget.onNavigateToSplit,
              ),
              const SizedBox(height: 22),

              // 5. Recent Activity Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkInk,
                    ),
                  ),
                  InkWell(
                    onTap: widget.onNavigateToExpenses,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.teal : AppColors.deepEmerald,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. Recent Transactions List or AppEmptyState (U1, Q3)
              if (recentExpenses.isEmpty)
                AppEmptyState(
                  icon: AppIcons.receipt,
                  title: 'No recent expenses',
                  message: 'Tap below to add your first expense.',
                  actionLabel: 'Add Expense',
                  onAction: () => _openAddExpenseModal(context),
                )
              else
                ...recentExpenses.map((exp) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2B27) : AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppIcons.wallet,
                            color: isDark ? AppColors.teal : AppColors.deepEmerald,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.darkInk,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${exp.category} • ${DateFormat('dd MMM').format(exp.date)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(exp.amount, isMasked: isMasked),
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkInk,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
