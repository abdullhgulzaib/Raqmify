import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class SplitTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const SplitTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF1E2826) : AppColors.surfaceSubtle;
    final cardBg = isDark ? const Color(0xFF253330) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildSplitTypeTab(context, 'Equal', 'Equal Split', Icons.balance_rounded, cardBg),
          _buildSplitTypeTab(context, 'Custom', 'Exact Amount', Icons.tune_rounded, cardBg),
          _buildSplitTypeTab(context, 'Percentage', 'Percentage %', Icons.percent_rounded, cardBg),
        ],
      ),
    );
  }

  Widget _buildSplitTypeTab(
    BuildContext context,
    String type,
    String label,
    IconData icon,
    Color cardBg,
  ) {
    final isSel = selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSel ? AppColors.deepEmerald : (isDark ? Colors.white60 : AppColors.textMuted),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? AppColors.deepEmerald : (isDark ? Colors.white70 : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
