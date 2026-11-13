import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../models/split_expense_model.dart';
import '../../../providers/split_provider.dart';

class SettlementProofModal {
  static void showSubmitProof({
    required BuildContext context,
    required String expenseId,
    required String expenseTitle,
    required String creditorName,
    required double amount,
    required String userId,
  }) {
    final tidController = TextEditingController();
    String method = 'Easypaisa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.darkInk;
          final inputBg = isDark ? const Color(0xFF24322F) : AppColors.surfaceSubtle;

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Submit Settlement Proof',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settling share for "$expenseTitle":',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs ${amount.toStringAsFixed(0)} owed to $creditorName',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  dropdownColor: dialogBg,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.textMuted),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Easypaisa', 'JazzCash', 'Bank Transfer', 'Cash'].map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m, style: TextStyle(color: textColor)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => method = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tidController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Transaction ID / Receipt # (e.g. EP-9831772)',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(AppIcons.receipt, color: AppColors.deepEmerald),
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
                  final tid = tidController.text.trim();
                  if (tid.isNotEmpty) {
                    Provider.of<SplitProvider>(context, listen: false).submitProof(
                      expenseId: expenseId,
                      userId: userId,
                      transactionId: tid,
                      paymentMethod: method,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Proof TID $tid submitted for verification!'),
                        backgroundColor: AppColors.deepEmerald,
                      ),
                    );
                  }
                },
                child: const Text('Submit Proof'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showReviewProof({
    required BuildContext context,
    required SplitExpenseModel expense,
    required SplitMemberShare share,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.darkInk;
        final containerBg = isDark ? const Color(0xFF16322B) : AppColors.lightEmerald;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Review Settlement Proof',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${share.name} claims payment for "${expense.title}":',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount Claimed:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          'Rs ${share.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Method:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          share.paymentMethod ?? 'Easypaisa',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transaction ID:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          share.proofTid ?? 'None',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF4FD1C5) : AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Verify against your wallet or bank statement before confirming.',
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final previousTid = share.proofTid;
                final previousMethod = share.paymentMethod;

                Provider.of<SplitProvider>(context, listen: false).verifyProof(
                  expenseId: expense.id,
                  userId: share.userId,
                  approve: false,
                );
                Navigator.pop(ctx);

                // 4-second floating, dismissible Undo SnackBar for settlement rejection
                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Payment marked as rejected.'),
                    backgroundColor: AppColors.errorRed,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    dismissDirection: DismissDirection.horizontal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        if (previousTid != null && previousMethod != null) {
                          Provider.of<SplitProvider>(context, listen: false).submitProof(
                            expenseId: expense.id,
                            userId: share.userId,
                            transactionId: previousTid,
                            paymentMethod: previousMethod,
                          );
                        }
                      },
                    ),
                  ),
                );
              },
              child: const Text('Reject', style: TextStyle(color: AppColors.errorRed)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Provider.of<SplitProvider>(context, listen: false).verifyProof(
                  expenseId: expense.id,
                  userId: share.userId,
                  approve: true,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment verified and marked Settled!'),
                    backgroundColor: AppColors.deepEmerald,
                  ),
                );
              },
              child: const Text('Verify & Settle'),
            ),
          ],
        );
      },
    );
  }
}
