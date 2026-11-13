import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../auth/widgets/security_verification_modal.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isMasked = authProvider.isPrivacyMasked;

    final breakdown = analyticsProvider.getCategoryBreakdown(expenseProvider.expenses);
    final totalSpend = expenseProvider.currentMonthTotal;

    final cardBg = isDark ? const Color(0xFF1E2826) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF101817);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2EAE5);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B19) : AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Expense Analytics',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isMasked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isMasked ? AppColors.mutedGold : (isDark ? const Color(0xFF68D391) : const Color(0xFF0B3D34)),
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
      body: breakdown.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: AppEmptyState(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No expense data to analyze',
                  message: 'Add expenses to see interactive breakdowns and visual charts.',
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Clean Minimal Donut Chart Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Spending Distribution',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Category breakdown for the current period',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF61716D),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Donut Chart
                        SizedBox(
                          height: 210,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse
                                            .touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 2.5,
                                  centerSpaceRadius: 64,
                                  sections: List.generate(breakdown.length, (i) {
                                    final isTouched = i == _touchedIndex;
                                    final cat = breakdown[i];

                                    return PieChartSectionData(
                                      color: cat.color,
                                      value: cat.totalAmount,
                                      showTitle: false,
                                      radius: isTouched ? 28.0 : 24.0,
                                    );
                                  }),
                                ),
                              ),

                              // Center Total Text
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'TOTAL SPEND',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white60 : const Color(0xFF61716D),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    CurrencyFormatter.format(totalSpend, isMasked: isMasked),
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF68D391) : const Color(0xFF0B3D34),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. High Spend Insight Card
                  if (breakdown.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF16322B) : const Color(0xFFE8F5F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.insights_rounded,
                              color: isDark ? const Color(0xFF68D391) : const Color(0xFF0B3D34),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Primary Expense Driver',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF68D391) : const Color(0xFF0B3D34),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${breakdown.first.category} represents ${breakdown.first.percentage.toStringAsFixed(1)}% (${CurrencyFormatter.format(breakdown.first.totalAmount, isMasked: isMasked)}) of your total spending.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : const Color(0xFF61716D),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 3. Category Breakdown & Legend
                  Text(
                    'Category Breakdown',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: breakdown.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cat = breakdown[index];
                      final isTouched = index == _touchedIndex;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isTouched
                                ? cat.color
                                : borderColor,
                            width: isTouched ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: cat.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.category,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${cat.percentage.toStringAsFixed(1)}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF61716D),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  CurrencyFormatter.format(cat.totalAmount, isMasked: isMasked),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF68D391) : const Color(0xFF0B3D34),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: cat.percentage / 100,
                                backgroundColor: isDark ? Colors.black26 : const Color(0xFFE2EAE5),
                                color: cat.color,
                                minHeight: 5,
                              ),
                            ),
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
}
