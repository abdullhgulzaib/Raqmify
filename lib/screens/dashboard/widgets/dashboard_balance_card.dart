import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/widgets/security_verification_modal.dart';

class DashboardBalanceCard extends StatelessWidget {
  final double monthTotal;
  final double dynamicDailyAvg;
  final bool isPrivacyMasked;
  final VoidCallback onToggleMask;
  final VoidCallback onAddExpense;
  final VoidCallback onSplitBill;
  final VoidCallback onAnalytics;

  const DashboardBalanceCard({
    super.key,
    required this.monthTotal,
    required this.dynamicDailyAvg,
    required this.isPrivacyMasked,
    required this.onToggleMask,
    required this.onAddExpense,
    required this.onSplitBill,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.emeraldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepEmerald.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Label & Privacy Mask Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL BALANCE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // U2
                icon: Icon(
                  isPrivacyMasked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 22,
                ),
                onPressed: () async {
                  if (isPrivacyMasked) {
                    final verified = await SecurityVerificationModal.verify(
                      context,
                      title: 'Unmask Financials',
                      subtitle: 'Enter PIN to reveal balance details',
                    );
                    if (verified) onToggleMask();
                  } else {
                    onToggleMask();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Spend Amount
          Text(
            CurrencyFormatter.format(monthTotal, isMasked: isPrivacyMasked),
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Row 3: Dynamic Daily Average Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.trendUp, size: 14, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(
                  'Daily Average: ${CurrencyFormatter.format(dynamicDailyAvg, isMasked: isPrivacyMasked)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Row 4: Quick Action Pills
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  icon: AppIcons.add,
                  label: 'Add Spend',
                  onTap: onAddExpense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.call_split_rounded,
                  label: 'Split Bill',
                  onTap: onSplitBill,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  icon: AppIcons.analytics,
                  label: 'Insights',
                  onTap: onAnalytics,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48, // U2
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
