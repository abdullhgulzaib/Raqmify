import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/split_provider.dart';
import '../auth/widgets/security_verification_modal.dart';
import 'widgets/create_split_expense_bottom_sheet.dart';
import 'widgets/split_activity_tab_view.dart';
import 'widgets/split_balances_tab_view.dart';
import 'widgets/split_groups_tab_view.dart';

class SplitVaultTab extends StatefulWidget {
  const SplitVaultTab({super.key});

  @override
  State<SplitVaultTab> createState() => _SplitVaultTabState();
}

class _SplitVaultTabState extends State<SplitVaultTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateSplitExpenseSheet([String? preselectedGroupId]) {
    CreateSplitExpenseBottomSheet.show(context, preselectedGroupId: preselectedGroupId);
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1B2422) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.darkInk;
        final inputBg = isDark ? const Color(0xFF24322F) : AppColors.surfaceSubtle;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Join Living Group',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the 8-character group invite code shared by your flatmate or roommates.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: textColor, letterSpacing: 1.5, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'e.g. 2345ABCD',
                  hintStyle: const TextStyle(letterSpacing: 0, fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.deepEmerald),
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
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                if (code.isNotEmpty) {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final result = await Provider.of<SplitProvider>(context, listen: false).joinGroupByInviteCode(
                    inviteCode: code,
                    userId: auth.currentUser?.id ?? 'demo_user_101',
                    userName: auth.currentUser?.name ?? 'Rana Abdullah',
                    userEmail: auth.currentUser?.email ?? 'rana@hostel.edu.pk',
                  );
                  final success = result is Success;
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Joined group with code $code!' : 'Group code not found or invalid format.'),
                        backgroundColor: success ? AppColors.deepEmerald : AppColors.errorRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Join Group'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Hostel';

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
              'Create Split Group',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Group Name (e.g. Hostel Room 304)',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(AppIcons.groups, color: AppColors.deepEmerald),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Description (e.g. Shared grocery & rent)',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.deepEmerald),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: dialogBg,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Hostel', 'Trip', 'Flat', 'Event'].map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c, style: TextStyle(color: textColor)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
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
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final user = auth.currentUser;
                    if (user == null || user.id.isEmpty) {
                      if (kReleaseMode) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please sign in to create a group.')),
                        );
                        return;
                      }
                    }
                    final currentUserId = user?.id.isNotEmpty == true ? user!.id : 'demo_user_101';
                    final currentUserName = user?.name.isNotEmpty == true ? user!.name : 'Living Group';
                    await Provider.of<SplitProvider>(context, listen: false).createGroup(
                      name: name,
                      description: descController.text.trim(),
                      category: category,
                      currentUserId: currentUserId,
                      currentUserName: currentUserName,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final splitProvider = Provider.of<SplitProvider>(context);

    final currentUserId = authProvider.currentUser?.id ?? 'demo_user_101';
    final isMasked = authProvider.isPrivacyMasked;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121B19) : AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Split Vault',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isMasked ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
            tooltip: 'Toggle privacy mask',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.deepEmerald,
          labelColor: AppColors.deepEmerald,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Balances', icon: Icon(Icons.balance_rounded, size: 18)),
            Tab(text: 'Groups', icon: Icon(AppIcons.groups, size: 18)),
            Tab(text: 'Activity', icon: Icon(Icons.history_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SplitBalancesTabView(
            splitProvider: splitProvider,
            currentUserId: currentUserId,
            isMasked: isMasked,
          ),
          SplitGroupsTabView(
            groups: splitProvider.groups,
            currentUserId: currentUserId,
            onJoinGroup: _showJoinGroupDialog,
            onCreateGroup: _showCreateGroupDialog,
          ),
          SplitActivityTabView(
            splitProvider: splitProvider,
            currentUserId: currentUserId,
            isMasked: isMasked,
            onCreateExpense: () => _showCreateSplitExpenseSheet(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSplitExpenseSheet(),
        backgroundColor: AppColors.deepEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.call_split_rounded),
        label: Text(
          'Split Expense',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
