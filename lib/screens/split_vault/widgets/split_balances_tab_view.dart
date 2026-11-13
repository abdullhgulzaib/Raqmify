import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../providers/split_provider.dart';
import 'settlement_proof_modal.dart';

class SplitBalancesTabView extends StatefulWidget {
  final SplitProvider splitProvider;
  final String currentUserId;
  final bool isMasked;

  const SplitBalancesTabView({
    super.key,
    required this.splitProvider,
    required this.currentUserId,
    required this.isMasked,
  });

  @override
  State<SplitBalancesTabView> createState() => _SplitBalancesTabViewState();
}

class _SplitBalancesTabViewState extends State<SplitBalancesTabView> {
  bool _aggregateAllGroups = false; // S8: Per-group default, optional aggregated

  Future<void> _sendWhatsAppReminder({
    required String debtorName,
    required double amount,
  }) async {
    final message =
        'Hi $debtorName, friendly reminder to settle Rs ${amount.toStringAsFixed(0)} on Raqmify. Track and settle on Raqmify: https://raqmify.app';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final splitProvider = widget.splitProvider;
    final currentUserId = widget.currentUserId;
    final isMasked = widget.isMasked;

    final debts = splitProvider.calculateNetBalances(
      currentUserId,
      aggregateAllGroups: _aggregateAllGroups,
    );

    final double amountYouOwe = debts
        .where((d) => d.fromUserId == currentUserId)
        .fold(0.0, (sum, d) => sum + d.netAmount.inRupees);

    final double amountYoureOwed = debts
        .where((d) => d.toUserId == currentUserId)
        .fold(0.0, (sum, d) => sum + d.netAmount.inRupees);

    final pendingVerifications = splitProvider.getPendingVerificationsForCreditor(currentUserId);

    return RefreshIndicator(
      onRefresh: () => splitProvider.fetchGroupsAndData(),
      color: AppColors.deepEmerald,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4 Analytics Stat Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildStatCard(
                  context: context,
                  title: 'Active Groups',
                  value: '${splitProvider.activeGroupsCount}',
                  subtitle: 'Total groups you belong to',
                  icon: AppIcons.groups,
                  iconColor: isDark ? const Color(0xFF68D391) : const Color(0xFF0B3D34),
                  isDarkCard: false,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Total Shared Spend',
                  value: CurrencyFormatter.format(splitProvider.totalSharedSpend, isMasked: isMasked),
                  subtitle: 'All shared expenses',
                  icon: AppIcons.wallet,
                  iconColor: const Color(0xFF16C79A),
                  isDarkCard: true,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Amount You Owe',
                  value: CurrencyFormatter.format(amountYouOwe, isMasked: isMasked),
                  subtitle: '${debts.where((d) => d.fromUserId == currentUserId).length} net debts due',
                  icon: Icons.arrow_outward_rounded,
                  iconColor: const Color(0xFFD4AF6B),
                  isDarkCard: true,
                ),
                _buildStatCard(
                  context: context,
                  title: "Amount You're Owed",
                  value: CurrencyFormatter.format(amountYoureOwed, isMasked: isMasked),
                  subtitle: '${pendingVerifications.length} proofs to approve',
                  icon: Icons.south_west_rounded,
                  iconColor: const Color(0xFF16C79A),
                  isDarkCard: false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Simplified Net Balances Header with Aggregate Toggle (S8)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.balance_rounded, color: AppColors.deepEmerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Simplified Net Balances',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkInk,
                      ),
                    ),
                  ],
                ),
                // Toggle between Per-Group and Aggregated (S8)
                InkWell(
                  onTap: () {
                    setState(() {
                      _aggregateAllGroups = !_aggregateAllGroups;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _aggregateAllGroups
                          ? AppColors.deepEmerald
                          : (isDark ? const Color(0xFF1E2826) : AppColors.lightEmerald),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _aggregateAllGroups ? 'Global Net' : 'Per Group',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _aggregateAllGroups
                            ? Colors.white
                            : (isDark ? const Color(0xFF68D391) : AppColors.deepEmerald),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Net Debts List
            if (debts.isEmpty)
              const AppEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'You are all settled',
                message: 'No outstanding balances in your groups.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: debts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final debt = debts[i];
                  final isDebtor = debt.fromUserId == currentUserId;
                  final isCreditor = debt.toUserId == currentUserId;

                  final cardBg = isDark
                      ? (isDebtor ? const Color(0xFF282318) : (isCreditor ? const Color(0xFF162B24) : const Color(0xFF1E2826)))
                      : (isDebtor ? const Color(0xFFFFFBEB) : (isCreditor ? const Color(0xFFF0FDF4) : Colors.white));

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDebtor
                            ? AppColors.pendingOrange.withValues(alpha: 0.3)
                            : (isCreditor
                                ? AppColors.successGreen.withValues(alpha: 0.3)
                                : (isDark ? AppColors.darkBorder : AppColors.borderLight)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Avatar initial
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isDebtor
                                  ? AppColors.pendingOrange.withValues(alpha: 0.2)
                                  : AppColors.successGreen.withValues(alpha: 0.2),
                              child: Text(
                                (isDebtor ? debt.toUserName : debt.fromUserName).isNotEmpty
                                    ? (isDebtor ? debt.toUserName : debt.fromUserName)[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: isDebtor ? AppColors.pendingOrange : AppColors.successGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Debt summary
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: isDark ? Colors.white : AppColors.darkInk,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: isDebtor ? 'You' : debt.fromUserName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isDebtor ? AppColors.pendingOrange : (isDark ? Colors.white : AppColors.darkInk),
                                          ),
                                        ),
                                        const TextSpan(text: ' owe '),
                                        TextSpan(
                                          text: isCreditor ? 'You' : debt.toUserName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isCreditor ? AppColors.successGreen : (isDark ? Colors.white : AppColors.darkInk),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    isDebtor ? 'You need to pay' : (isCreditor ? 'To be received' : 'Mutual balance'),
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),

                            // Amount
                            Text(
                              CurrencyFormatter.format(debt.netAmount.inRupees, isMasked: isMasked),
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDebtor ? AppColors.pendingOrange : AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),

                        // Action Buttons Row (F1 Proof submission, F5 WhatsApp reminder)
                        if (isDebtor || isCreditor) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Under review indicator or Submit Proof button
                              if (isDebtor) ...[
                                if (debt.hasPendingReview)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.pendingOrange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(AppIcons.time, size: 14, color: AppColors.pendingOrange),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Proof Submitted',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.pendingOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  TextButton.icon(
                                    onPressed: () {
                                      final exp = splitProvider.groupExpenses.firstWhere(
                                        (e) => e.splits.any((s) => s.userId == currentUserId && s.status != 'Settled'),
                                        orElse: () => splitProvider.groupExpenses.first,
                                      );
                                      SettlementProofModal.showSubmitProof(
                                        context: context,
                                        expenseId: exp.id,
                                        expenseTitle: exp.title,
                                        creditorName: debt.toUserName,
                                        amount: debt.netAmount.inRupees,
                                        userId: currentUserId,
                                      );
                                    },
                                    icon: const Icon(AppIcons.receipt, size: 15, color: AppColors.deepEmerald),
                                    label: Text(
                                      'Submit Proof',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepEmerald,
                                      ),
                                    ),
                                  ),
                              ],

                              // WhatsApp Reminder for Creditor (F5)
                              if (isCreditor) ...[
                                if (debt.hasPendingReview) ...[
                                  TextButton.icon(
                                    onPressed: () {
                                      final item = pendingVerifications.where((p) => p.share.userId == debt.fromUserId).firstOrNull;
                                      if (item != null) {
                                        SettlementProofModal.showReviewProof(
                                          context: context,
                                          expense: item.expense,
                                          share: item.share,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.rate_review_rounded, size: 15, color: AppColors.deepEmerald),
                                    label: Text(
                                      'Review Proof',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepEmerald,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                TextButton.icon(
                                  onPressed: () => _sendWhatsAppReminder(
                                    debtorName: debt.fromUserName,
                                    amount: debt.netAmount.inRupees,
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF25D366)),
                                  label: Text(
                                    'Remind on WhatsApp',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF25D366),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDarkCard,
  }) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkTheme
        ? (isDarkCard ? const Color(0xFF1A3831) : const Color(0xFF1E2826))
        : (isDarkCard ? const Color(0xFF07382E) : Colors.white);

    final titleColor = isDarkTheme
        ? (isDarkCard ? Colors.white70 : AppColors.textMuted)
        : (isDarkCard ? Colors.white70 : AppColors.textMuted);

    final valColor = isDarkTheme
        ? Colors.white
        : (isDarkCard ? Colors.white : AppColors.darkInk);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkTheme ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valColor,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isDarkCard ? Colors.white60 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
