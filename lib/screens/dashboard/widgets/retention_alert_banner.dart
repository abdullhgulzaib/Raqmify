import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/services/retention_service.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../models/expense_model.dart';

class RetentionAlertBanner extends StatelessWidget {
  final RetentionStatus status;
  final List<ExpenseModel> expenses;
  final String userName;
  final String userEmail;
  final VoidCallback? onDismiss;

  const RetentionAlertBanner({
    super.key,
    required this.status,
    required this.expenses,
    required this.userName,
    required this.userEmail,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!status.isApproachingPrune) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF5C2626) : const Color(0xFFFECACA),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.warning, color: AppColors.errorRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '60-Day Data Pruning Notice',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF991B1B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${status.daysRemaining}d left',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: isDark ? Colors.white70 : const Color(0xFF991B1B),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Dismiss alert',
                  onPressed: onDismiss,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${status.affectedRecordCount} records will be archived soon under the 60-day university lab retention policy.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: isDark ? Colors.grey[300] : const Color(0xFF7F1D1D),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () {
                PdfStatementGenerator.printOrShareStatement(
                  userName: userName,
                  userEmail: userEmail,
                  expenses: expenses,
                  periodName: 'Retention Backup (Past 60 Days)',
                );
                onDismiss?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF statement exported. Retention notice dismissed.'),
                    backgroundColor: AppColors.deepEmerald,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(AppIcons.download, size: 16),
              label: const Text('Download PDF Statement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
