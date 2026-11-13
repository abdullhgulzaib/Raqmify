import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../models/split_expense_model.dart';
import '../../../providers/split_provider.dart';
import '../../auth/widgets/security_verification_modal.dart';
import 'settlement_proof_modal.dart';

class SplitActivityTabView extends StatefulWidget {
  final SplitProvider splitProvider;
  final String currentUserId;
  final bool isMasked;
  final VoidCallback onCreateExpense;

  const SplitActivityTabView({
    super.key,
    required this.splitProvider,
    required this.currentUserId,
    required this.isMasked,
    required this.onCreateExpense,
  });

  @override
  State<SplitActivityTabView> createState() => _SplitActivityTabViewState();
}

class _SplitActivityTabViewState extends State<SplitActivityTabView> {
  String _selectedGroupId = 'all';
  final Map<String, bool> _expandedExpenses = {};

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'groceries':
        return Icons.shopping_basket_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'housing':
      case 'rent':
        return Icons.home_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  void _deleteExpenseWithUndo(SplitExpenseModel expense) async {
    final verified = await SecurityVerificationModal.verify(
      context,
      title: 'Authorize Expense Deletion',
      subtitle: 'Scan fingerprint or enter PIN to delete shared expense',
    );
    if (!verified || !mounted) return;

    final provider = widget.splitProvider;
    await provider.deleteSplitExpense(expense.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense "${expense.title}" deleted.'),
          backgroundColor: AppColors.deepEmerald,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.teal,
            onPressed: () {
              provider.restoreSplitExpense(expense);
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
    final groups = splitProvider.groups;
    final expenses = splitProvider.getExpensesForGroup(_selectedGroupId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          if (groups.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Activity'),
                    selected: _selectedGroupId == 'all',
                    selectedColor: AppColors.deepEmerald,
                    backgroundColor: isDark ? const Color(0xFF1E2826) : AppColors.surfaceSubtle,
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: _selectedGroupId == 'all' ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedGroupId == 'all'
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.darkInk),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (val) {
                      if (val) setState(() => _selectedGroupId = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  ...groups.map((g) {
                    final isSel = _selectedGroupId == g.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g.name),
                        selected: isSel,
                        selectedColor: AppColors.deepEmerald,
                        backgroundColor: isDark ? const Color(0xFF1E2826) : AppColors.surfaceSubtle,
                        labelStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.darkInk),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val) setState(() => _selectedGroupId = g.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Expenses List or Empty State
          if (expenses.isEmpty)
            AppEmptyState(
              icon: AppIcons.receipt,
              title: 'No Split Expenses Recorded',
              message: 'Shared expenses added by you or group members will appear here in chronological order.',
              actionLabel: 'Add Split Expense',
              onAction: widget.onCreateExpense,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final expense = expenses[idx];
                final isExpanded = _expandedExpenses[expense.id] ?? false;
                final isPayer = expense.paidByUserId == widget.currentUserId;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2826) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedExpenses[expense.id] = !isExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1A3831) : AppColors.lightEmerald,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
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
                                      expense.title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.darkInk,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isPayer ? "You paid" : "${expense.paidByName} paid"}  •  ${DateFormat('MMM d, yyyy').format(expense.date)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(expense.totalAmount, isMasked: widget.isMasked),
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                                    ),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded breakdown
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (expense.notes.isNotEmpty) ...[
                                Text(
                                  'Note: ${expense.notes}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              Text(
                                'Split Breakdown (${expense.splitType})',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...expense.splits.map((s) {
                                final isUserShare = s.userId == widget.currentUserId;
                                final canSubmitProof = isUserShare && !isPayer && s.status == 'Unpaid';
                                final canReviewProof = isPayer && !isUserShare && s.status == 'UnderReview';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isUserShare ? '${s.name} (You)' : s.name,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: isUserShare ? FontWeight.w700 : FontWeight.w500,
                                                    color: isDark ? Colors.white70 : AppColors.darkInk,
                                                  ),
                                                ),
                                                if (s.proofTid != null && s.proofTid!.isNotEmpty)
                                                  Text(
                                                    'TID: ${s.proofTid}',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      color: AppColors.pendingOrange,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                CurrencyFormatter.format(s.amount, isMasked: widget.isMasked),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : AppColors.darkInk,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: s.status == 'Settled' || s.status == 'Verified'
                                                      ? AppColors.successGreen.withValues(alpha: 0.15)
                                                      : (s.status == 'UnderReview'
                                                          ? AppColors.pendingOrange.withValues(alpha: 0.15)
                                                          : Colors.grey.withValues(alpha: 0.15)),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  s.status,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: s.status == 'Settled' || s.status == 'Verified'
                                                        ? AppColors.successGreen
                                                        : (s.status == 'UnderReview'
                                                            ? AppColors.pendingOrange
                                                            : AppColors.textMuted),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (canSubmitProof || canReviewProof) ...[
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: canSubmitProof
                                              ? InkWell(
                                                  onTap: () {
                                                    SettlementProofModal.showSubmitProof(
                                                      context: context,
                                                      expenseId: expense.id,
                                                      expenseTitle: expense.title,
                                                      creditorName: expense.paidByName,
                                                      amount: s.amount,
                                                      userId: widget.currentUserId,
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.deepEmerald.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Submit Proof TID',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.deepEmerald,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : InkWell(
                                                  onTap: () {
                                                    SettlementProofModal.showReviewProof(
                                                      context: context,
                                                      expense: expense,
                                                      share: s,
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.pendingOrange.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Review Proof',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.pendingOrange,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _deleteExpenseWithUndo(expense),
                                  icon: const Icon(AppIcons.trash, size: 14, color: AppColors.errorRed),
                                  label: const Text(
                                    'Delete Expense',
                                    style: TextStyle(color: AppColors.errorRed, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
