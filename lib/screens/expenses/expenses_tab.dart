import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/pdf_generator.dart';
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

  void _showExpenseDetail(ExpenseModel exp, bool isMasked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: AppColors.borderLight,
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
                        color: AppColors.darkInk,
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
                      AddExpenseBottomSheet.edit(context, exp);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                    tooltip: 'Delete Expense',
                    onPressed: () async {
                      final verified = await SecurityVerificationModal.verify(
                        context,
                        title: 'Authorize Deletion',
                        subtitle: 'Scan fingerprint or enter PIN to delete expense',
                      );
                      if (!verified || !context.mounted) return;
                      Provider.of<ExpenseProvider>(context, listen: false).deleteExpense(exp.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expense deleted'),
                          backgroundColor: AppColors.darkInk,
                        ),
                      );
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
                  color: AppColors.deepEmerald,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('Category', exp.category),
              const SizedBox(height: 8),
              _buildDetailRow('Date', DateFormat('dd MMMM yyyy, hh:mm a').format(exp.date)),
              const SizedBox(height: 8),
              _buildDetailRow('Payment Method', exp.paymentMethod),
              if (exp.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Notes', exp.notes),
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

  Widget _buildDetailRow(String label, String value) {
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
            color: AppColors.darkInk,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isMasked = authProvider.isPrivacyMasked;

    final filteredExpenses = expenseProvider.filteredExpenses;
    final totalFiltered = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Personal Expenses',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkInk,
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
                  authProvider.togglePrivacyMask();
                }
              } else {
                authProvider.togglePrivacyMask();
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
              decoration: InputDecoration(
                hintText: 'Search expenses by name or notes...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
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
                      color: isSelected ? Colors.white : AppColors.darkInk,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.deepEmerald : AppColors.borderLight,
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
                    color: AppColors.deepEmerald,
                  ),
                ),
              ],
            ),
          ),

          // 4. Expenses List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.deepEmerald,
              onRefresh: () async {
                if (!authProvider.isDemoUser) {
                  await expenseProvider.fetchExpenses();
                }
              },
              child: filteredExpenses.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                  'No matching expenses found',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkInk,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your search query or category filters, or tap + to add your first expense.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final exp = filteredExpenses[index];
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
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          expenseProvider.deleteExpense(exp.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted "${exp.title}"'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: InkWell(
                          onTap: () => _showExpenseDetail(exp, isMasked),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSubtle,
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
                                          color: AppColors.darkInk,
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
                                              color: AppColors.surfaceSubtle,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              exp.paymentMethod,
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.darkInk,
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
                                    color: AppColors.darkInk,
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
