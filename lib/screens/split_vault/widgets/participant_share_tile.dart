import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/money_input_formatter.dart';

class ParticipantSplitItem {
  final String userId;
  final String name;
  final String email;
  final bool isCurrentUser;
  bool selected;
  double amount;
  double percentage;
  TextEditingController amountController;
  TextEditingController pctController;

  ParticipantSplitItem({
    required this.userId,
    required this.name,
    this.email = '',
    required this.isCurrentUser,
    this.selected = true,
    this.amount = 0.0,
    this.percentage = 0.0,
  })  : amountController = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : ''),
        pctController = TextEditingController(text: percentage > 0 ? percentage.toStringAsFixed(1) : '');

  void dispose() {
    amountController.dispose();
    pctController.dispose();
  }
}

class ParticipantShareTile extends StatelessWidget {
  final ParticipantSplitItem participant;
  final String splitType;
  final double totalAmount;
  final VoidCallback onToggle;
  final ValueChanged<String>? onAmountChanged;
  final ValueChanged<String>? onPercentageChanged;

  const ParticipantShareTile({
    super.key,
    required this.participant,
    required this.splitType,
    required this.totalAmount,
    required this.onToggle,
    this.onAmountChanged,
    this.onPercentageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? (participant.selected ? const Color(0xFF253330) : const Color(0xFF1E2826))
        : (participant.selected ? Colors.white : AppColors.surfaceSubtle.withValues(alpha: 0.5));
    final textColor = isDark ? Colors.white : AppColors.darkInk;
    final inputBg = isDark ? const Color(0xFF1B2422) : AppColors.surfaceSubtle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: participant.selected
              ? (isDark ? AppColors.darkBorder : AppColors.borderLight)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Checkbox with minimum touch target
          SizedBox(
            width: 44,
            height: 44,
            child: Checkbox(
              value: participant.selected,
              activeColor: AppColors.deepEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              onChanged: (_) => onToggle(),
            ),
          ),

          // Initial Circle Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: participant.isCurrentUser
                ? AppColors.deepEmerald
                : AppColors.deepEmerald.withValues(alpha: 0.15),
            child: Text(
              participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: participant.isCurrentUser ? Colors.white : AppColors.deepEmerald,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and Payer badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: participant.isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                    color: participant.selected ? textColor : AppColors.textMuted,
                  ),
                ),
                if (participant.isCurrentUser)
                  Text(
                    'Payer (You paid)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Share input or display
          if (splitType == 'Equal')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: participant.selected
                    ? (isDark ? const Color(0xFF1A3831) : AppColors.lightEmerald)
                    : inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                participant.selected ? 'Rs ${participant.amount.toStringAsFixed(0)}' : 'Excluded',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: participant.selected
                      ? (isDark ? const Color(0xFF68D391) : AppColors.deepEmerald)
                      : AppColors.textMuted,
                ),
              ),
            )
          else if (splitType == 'Custom')
            SizedBox(
              width: 110,
              child: TextField(
                controller: participant.amountController,
                enabled: participant.selected,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  MoneyInputFormatter(),
                ],
                textAlign: TextAlign.right,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rs ',
                  prefixStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: participant.selected ? inputBg : (isDark ? Colors.black12 : Colors.grey[200]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: onAmountChanged,
              ),
            )
          else if (splitType == 'Percentage')
            SizedBox(
              width: 80,
              child: TextField(
                controller: participant.pctController,
                enabled: participant.selected,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: participant.selected ? inputBg : (isDark ? Colors.black12 : Colors.grey[200]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: onPercentageChanged,
              ),
            ),
        ],
      ),
    );
  }
}
