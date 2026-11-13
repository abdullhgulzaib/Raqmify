import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../auth/widgets/security_verification_modal.dart';
import '../dashboard/widgets/add_expense_bottom_sheet.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Food',
    'Housing',
    'Transportation',
    'Groceries',
    'Bills',
    'Education',
    'Health',
    'Shopping',
    'Entertainment',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        return Icons.shopping_basket_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_creation_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  void _deleteExpenseWithUndo(ExpenseModel exp) async {
    final verified = await SecurityVerificationModal.verify(
      context,
      title: 'Authorize Deletion',
      subtitle: 'Scan fingerprint or enter PIN to delete expense',
    );
    if (!verified || !mounted) return;

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.deleteExpense(exp.id);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted "${exp.title}"'),
          backgroundColor: AppColors.deepEmerald,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.teal,
            onPressed: () {
              messenger.hideCurrentSnackBar();
              provider.restoreExpense(exp);
            },
          ),
        ),
      );
    }
  }

  void _showExpenseDetail(ExpenseModel exp, bool isMasked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF141E1C) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.darkInk;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exp.title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.deepEmerald),
                    tooltip: 'Edit Expense',
                    onPressed: () async {
                      final verified = await SecurityVerificationModal.verify(
                        context,
                        title: 'Authorize Edit',
                        subtitle: 'Scan fingerprint or enter PIN to edit expense',
                      );
                      if (!verified || !context.mounted) return;
                      Navigator.pop(context);
                      await AddExpenseBottomSheet.edit(context, exp);
                    },
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.trash, color: AppColors.errorRed),
                    tooltip: 'Delete Expense',
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteExpenseWithUndo(exp);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(exp.amount, isMasked: isMasked),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
              const SizedBox(height: 12),
              _buildDetailRow('Category', exp.category, isDark),
              const SizedBox(height: 8),
              _buildDetailRow('Date', DateFormat('dd MMMM yyyy, hh:mm a').format(exp.date), isDark),
              const SizedBox(height: 8),
              _buildDetailRow('Payment Method', exp.paymentMethod, isDark),
              if (exp.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Notes', exp.notes, isDark),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text('Edit Expense', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.pop(context);
                        AddExpenseBottomSheet.edit(context, exp);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.darkInk,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isMasked = authProvider.isPrivacyMasked;

    final filteredExpenses = expenseProvider.filteredExpenses;
    final totalFiltered = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B19) : AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Personal Expenses',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkInk,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.deepEmerald),
            tooltip: 'Export PDF Statement',
            onPressed: () async {
              final verified = await SecurityVerificationModal.verify(
                context,
                title: 'Authorize Statement Export',
                subtitle: 'Scan fingerprint or enter PIN to export PDF',
              );
              if (!verified || !context.mounted) return;

              final expenses = expenseProvider.expenses;
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
                      Text('Generating PDF (${expenses.length} records)...', style: GoogleFonts.outfit()),
                    ],
                  ),
                  backgroundColor: AppColors.deepEmerald,
                  duration: const Duration(seconds: 2),
                ),
              );
              await PdfStatementGenerator.printOrShareStatement(
                expenses: expenses,
                userName: authProvider.currentUser?.name ?? 'Rana Abdullah',
                userEmail: authProvider.currentUser?.email ?? 'user@raqmify.app',
                periodName: DateFormat('MMMM yyyy').format(DateTime.now()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isMasked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isMasked ? AppColors.mutedGold : AppColors.deepEmerald,
            ),
            onPressed: () async {
              if (isMasked && authProvider.hasPin) {
                final verified = await SecurityVerificationModal.verify(
                  context,
                  title: 'Unlock Privacy Vault',
                  subtitle: 'Scan fingerprint or enter PIN to reveal balance',
                );
                if (verified) {
                  await authProvider.togglePrivacyMask(force: true);
                }
              } else {
                await authProvider.togglePrivacyMask();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => expenseProvider.setSearchQuery(val),
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkInk),
              decoration: InputDecoration(
                hintText: 'Search expenses by name or notes...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2826) : Colors.white,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          expenseProvider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = expenseProvider.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      expenseProvider.setSelectedCategory(selected ? cat : 'All');
                    },
                    selectedColor: AppColors.deepEmerald,
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.darkInk),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E2826) : Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.deepEmerald : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Filter Summary Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredExpenses.length} Records Found',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  'Total: ${CurrencyFormatter.format(totalFiltered, isMasked: isMasked)}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                  ),
                ),
              ],
            ),
          ),

          // 4. Expenses List / Shimmer (U1)
          Expanded(
            child: RefreshIndicator(
              color: AppColors.deepEmerald,
              onRefresh: () async {
                if (!authProvider.isDemoUser) {
                  await expenseProvider.fetchExpenses();
                }
              },
              child: expenseProvider.isLoading && filteredExpenses.isEmpty
                  ? const ShimmerListPlaceholder(itemCount: 7)
                  : filteredExpenses.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 60),
                            AppEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No matching expenses found',
                              message: 'Try adjusting your search query or filters, or tap + to record your first expense.',
                              actionLabel: 'Add Expense',
                              onAction: () => AddExpenseBottomSheet.show(context),
                            ),
                          ],
                        )
                      : ListView.separated(
                          // U7: Bottom padding >= 88 dp for FAB clearance
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 92),
                          itemCount: filteredExpenses.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final exp = filteredExpenses[index];
                            final isSyncFailed = exp.syncStatus == 'failed';
                            final isSyncPending = exp.syncStatus == 'pending';

                            return Dismissible(
                              key: Key(exp.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await SecurityVerificationModal.verify(
                                  context,
                                  title: 'Authorize Deletion',
                                  subtitle: 'Scan fingerprint or enter PIN to delete expense',
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(AppIcons.trash, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                expenseProvider.deleteExpense(exp.id);
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted "${exp.title}"'),
                                    backgroundColor: AppColors.deepEmerald,
                                    duration: const Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                    dismissDirection: DismissDirection.horizontal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: AppColors.teal,
                                      onPressed: () {
                                        messenger.hideCurrentSnackBar();
                                        expenseProvider.restoreExpense(exp);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: InkWell(
                                onTap: () => _showExpenseDetail(exp, isMasked),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E2826) : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSyncFailed
                                          ? AppColors.errorRed.withValues(alpha: 0.4)
                                          : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1A3831) : AppColors.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(exp.category),
                                          color: AppColors.deepEmerald,
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
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : AppColors.darkInk,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  DateFormat('dd MMM yyyy').format(exp.date),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF162421) : AppColors.surfaceSubtle,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    exp.paymentMethod,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? Colors.white70 : AppColors.darkInk,
                                                    ),
                                                  ),
                                                ),
                                                // S5: Sync status badge
                                                if (isSyncFailed) ...[
                                                  const SizedBox(width: 6),
                                                  InkWell(
                                                    onTap: () {
                                                      expenseProvider.retrySync(exp.id);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Retrying sync...'),
                                                          duration: Duration(seconds: 1),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.errorRed.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.sync_problem_rounded, size: 10, color: AppColors.errorRed),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            'Retry',
                                                            style: GoogleFonts.outfit(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w700,
                                                              color: AppColors.errorRed,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ] else if (isSyncPending) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(AppIcons.time, size: 12, color: AppColors.pendingOrange),
                                                ],
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
                                          color: isDark ? Colors.white : AppColors.darkInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
