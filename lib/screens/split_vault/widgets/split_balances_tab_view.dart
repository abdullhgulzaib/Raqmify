import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_normalizer.dart';
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
  Future<void> _sendWhatsAppReminder({
    required String debtorName,
    required String debtorId,
    required double amount,
    String rawPhone = '',
    String groupName = '',
  }) async {
    final phoneDigits = normalizePhoneToInternationalDigits(rawPhone);
    final groupText = groupName.isNotEmpty ? ' for $groupName' : '';
    final message =
        'Hi $debtorName, a friendly reminder to settle Rs ${amount.toStringAsFixed(2)}$groupText on Raqmify.';

    // Call POST /api/splitvault/nudge (fire and forget)
    unawaited(widget.splitProvider.sendNudge(
      debtorId: debtorId,
      amount: amount,
      groupName: groupName,
    ));

    bool opened = false;

    // (a) Try direct WhatsApp URI
    try {
      final directUri = Uri.parse(buildWhatsAppDirectUrl(phoneDigits, message));
      opened = await launchUrl(directUri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    // (b) Try web wa.me URL
    if (!opened) {
      try {
        final webUri = Uri.parse(buildWhatsAppWebUrl(phoneDigits, message));
        opened = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    // (c) Fallback: Copy message action
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open WhatsApp.'),
          action: SnackBarAction(
            label: 'Copy message',
            textColor: Colors.white,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder copied to clipboard.')),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final splitProvider = widget.splitProvider;
    final currentUserId = widget.currentUserId;
    final isMasked = widget.isMasked;

    // Server-computed net settlements filtered to current user
    final allNetSettlements = splitProvider.netSettlements;
    final userNetDebts = allNetSettlements
        .where((s) => s.fromUserId == currentUserId || s.toUserId == currentUserId)
        .toList();

    final double amountYouOwe = allNetSettlements
        .where((s) => s.fromUserId == currentUserId)
        .fold(0.0, (sum, s) => sum + s.amount);

    final double amountYoureOwed = allNetSettlements
        .where((s) => s.toUserId == currentUserId)
        .fold(0.0, (sum, s) => sum + s.amount);

    final pendingSettlementsToVerify = splitProvider.pendingSettlementsToVerify;

    return RefreshIndicator(
      onRefresh: () => splitProvider.fetchGroupsAndData(currentUserId: currentUserId),
      color: AppColors.deepEmerald,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  subtitle: '${allNetSettlements.where((s) => s.fromUserId == currentUserId).length} net debts due',
                  icon: Icons.arrow_outward_rounded,
                  iconColor: const Color(0xFFD4AF6B),
                  isDarkCard: true,
                ),
                _buildStatCard(
                  context: context,
                  title: "Amount You're Owed",
                  value: CurrencyFormatter.format(amountYoureOwed, isMasked: isMasked),
                  subtitle: '${pendingSettlementsToVerify.length} settlements to review',
                  icon: Icons.south_west_rounded,
                  iconColor: const Color(0xFF16C79A),
                  isDarkCard: false,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pending Net Settlement Proofs for Creditor
            if (pendingSettlementsToVerify.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2215) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.pendingOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded, color: AppColors.pendingOrange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pending Settlements to Review (${pendingSettlementsToVerify.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...pendingSettlementsToVerify.map((settlement) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${settlement.fromUserName} • Rs ${settlement.amount.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppColors.darkInk,
                                    ),
                                  ),
                                  Text(
                                    '${settlement.proof?.method ?? "Easypaisa"} • TID: ${settlement.proof?.transactionId.isNotEmpty == true ? settlement.proof!.transactionId : "Attached"}',
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.deepEmerald,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                SettlementProofModal.showReviewNetSettlement(
                                  context: context,
                                  settlement: settlement,
                                  currentUserId: currentUserId,
                                );
                              },
                              child: const Text('Review', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Simplified Net Balances Header
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
            const SizedBox(height: 12),

            // Net Debts List from Server
            if (userNetDebts.isEmpty)
              const AppEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'You are all settled',
                message: 'No outstanding balances in your groups.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userNetDebts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final net = userNetDebts[i];
                  final isDebtor = net.fromUserId == currentUserId;
                  final isCreditor = net.toUserId == currentUserId;

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
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isDebtor
                                  ? AppColors.pendingOrange.withValues(alpha: 0.2)
                                  : AppColors.successGreen.withValues(alpha: 0.2),
                              child: Text(
                                (isDebtor ? net.toUser : net.fromUser).isNotEmpty
                                    ? (isDebtor ? net.toUser : net.fromUser)[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: isDebtor ? AppColors.pendingOrange : AppColors.successGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

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
                                          text: isDebtor ? 'You' : net.fromUser,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isDebtor ? AppColors.pendingOrange : (isDark ? Colors.white : AppColors.darkInk),
                                          ),
                                        ),
                                        const TextSpan(text: ' owe '),
                                        TextSpan(
                                          text: isCreditor ? 'You' : net.toUser,
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

                            Text(
                              CurrencyFormatter.format(net.amount, isMasked: isMasked),
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDebtor ? AppColors.pendingOrange : AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),

                        // Action Buttons Row
                        if (isDebtor || isCreditor) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Debtor Actions
                              if (isDebtor) ...[
                                if (net.hasPendingSettlement)
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
                                          'Waiting for ${net.toUser} to verify',
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
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.deepEmerald,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      SettlementProofModal.showSubmitNetSettlementProof(
                                        context: context,
                                        toUserId: net.toUserId,
                                        creditorName: net.toUser,
                                        amount: net.amount,
                                        currentUserId: currentUserId,
                                      );
                                    },
                                    icon: const Icon(AppIcons.receipt, size: 15, color: Colors.white),
                                    label: Text(
                                      'Settle Balance',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],

                              // Creditor Actions (Review & WhatsApp Reminder strictly for creditor)
                              if (isCreditor) ...[
                                if (net.hasPendingSettlement) ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.deepEmerald,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      final pendingItem = pendingSettlementsToVerify
                                          .where((s) => s.fromUser == net.fromUserId)
                                          .firstOrNull;
                                      if (pendingItem != null) {
                                        SettlementProofModal.showReviewNetSettlement(
                                          context: context,
                                          settlement: pendingItem,
                                          currentUserId: currentUserId,
                                        );
                                      } else if (net.pendingSettlementId != null) {
                                        final matched = splitProvider.settlements
                                            .where((s) => s.id == net.pendingSettlementId)
                                            .firstOrNull;
                                        if (matched != null) {
                                          SettlementProofModal.showReviewNetSettlement(
                                            context: context,
                                            settlement: matched,
                                            currentUserId: currentUserId,
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.rate_review_rounded, size: 15, color: Colors.white),
                                    label: Text(
                                      'Review Proof',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                TextButton.icon(
                                  onPressed: () => _sendWhatsAppReminder(
                                    debtorName: net.fromUser,
                                    debtorId: net.fromUserId,
                                    amount: net.amount,
                                    rawPhone: net.recipientPaymentDetails.phone,
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
