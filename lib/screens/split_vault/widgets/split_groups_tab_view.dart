import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../models/group_model.dart';
import '../../../providers/split_provider.dart';
import 'group_details_sheet.dart';

class SplitGroupsTabView extends StatelessWidget {
  final List<GroupModel> groups;
  final String currentUserId;
  final VoidCallback onJoinGroup;
  final VoidCallback onCreateGroup;

  const SplitGroupsTabView({
    super.key,
    required this.groups,
    required this.currentUserId,
    required this.onJoinGroup,
    required this.onCreateGroup,
  });

  void _showGroupDetailsModal(BuildContext context, GroupModel group) {
    GroupDetailsSheet.show(
      context,
      group: group,
      currentUserId: currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final splitProvider = Provider.of<SplitProvider>(context);

    return RefreshIndicator(
      onRefresh: () => splitProvider.fetchGroupsAndData(),
      color: AppColors.deepEmerald,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Buttons: Join & Create
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onJoinGroup,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepEmerald,
                    side: const BorderSide(color: AppColors.deepEmerald),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.vpn_key_rounded, size: 18),
                  label: Text(
                    'Join Group',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCreateGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.group_add_rounded, size: 18),
                  label: Text(
                    'Create Group',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Groups Header
          Text(
            'Your Living Groups (${groups.length})',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkInk,
            ),
          ),
          const SizedBox(height: 12),

          // Group List or Empty State
          if (groups.isEmpty)
            AppEmptyState(
              icon: AppIcons.groups,
              title: 'No Living Groups Yet',
              message: 'Create or join a group with flatmates or travel friends to split expenses easily.',
              actionLabel: 'Create Group',
              onAction: onCreateGroup,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final group = groups[idx];
                final groupExpenses = splitProvider.getExpensesForGroup(group.id);
                final totalGroupSpend = groupExpenses.fold<double>(0.0, (sum, e) => sum + e.totalAmount);

                return InkWell(
                  onTap: () => _showGroupDetailsModal(context, group),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1A3831) : AppColors.lightEmerald,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    AppIcons.groups,
                                    color: AppColors.deepEmerald,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.darkInk,
                                      ),
                                    ),
                                    Text(
                                      '${group.members.length} members  •  Code: ${group.inviteCode}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Spend: ${CurrencyFormatter.format(totalGroupSpend)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF162B24) : AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                group.category,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
