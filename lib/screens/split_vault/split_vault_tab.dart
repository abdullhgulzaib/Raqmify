import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/group_model.dart';
import '../../models/split_expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/split_provider.dart';
import '../auth/widgets/security_verification_modal.dart';
import 'widgets/create_split_expense_bottom_sheet.dart';

class SplitVaultTab extends StatefulWidget {
  const SplitVaultTab({super.key});

  @override
  State<SplitVaultTab> createState() => _SplitVaultTabState();
}

class _SplitVaultTabState extends State<SplitVaultTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedActivityGroupId = 'all';
  final Map<String, bool> _expandedExpenses = {};

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

  // --- Modal Helpers ---

  void _showCreateSplitExpenseSheet([String? preselectedGroupId]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateSplitExpenseBottomSheet(
        preselectedGroupId: preselectedGroupId,
      ),
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Join Living Group',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-character group invite code shared by your flatmate or roommates.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. HOSTEL or TRIP26',
                prefixIcon: Icon(Icons.vpn_key_rounded, color: AppColors.deepEmerald),
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
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<SplitProvider>(context, listen: false).joinGroupByInviteCode(
                  inviteCode: code,
                  userId: auth.currentUser?.id ?? 'demo_user_101',
                  userName: auth.currentUser?.name ?? 'Rana Abdullah',
                  userEmail: auth.currentUser?.email ?? 'rana@hostel.edu.pk',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Joined group with code $code!' : 'Group code not found.'),
                      backgroundColor: success ? AppColors.deepEmerald : AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Join Group'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Hostel';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create Split Group',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Group Name (e.g. Hostel Room 304)',
                  prefixIcon: Icon(Icons.group_rounded, color: AppColors.deepEmerald),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  hintText: 'Description (e.g. Shared grocery & rent)',
                  prefixIcon: Icon(Icons.notes_rounded, color: AppColors.deepEmerald),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Hostel', 'Trip', 'Flat', 'Event'].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
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
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await Provider.of<SplitProvider>(context, listen: false).createGroup(
                    name: name,
                    description: descController.text.trim(),
                    category: category,
                    currentUserId: auth.currentUser?.id ?? 'demo_user_101',
                    currentUserName: auth.currentUser?.name ?? 'Rana Abdullah',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteGroupDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Group',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.errorRed),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? All associated shared expenses and records in this group will be removed.',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white),
            onPressed: () async {
              final verified = await SecurityVerificationModal.verify(
                ctx,
                title: 'Authorize Group Deletion',
                subtitle: 'Scan fingerprint or enter PIN to delete group',
              );
              if (!verified || !mounted) return;
              Provider.of<SplitProvider>(context, listen: false).deleteGroup(group.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Group "${group.name}" deleted.'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteExpenseDialog(SplitExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Shared Expense',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.errorRed),
        ),
        content: Text(
          'Are you sure you want to delete "${expense.title}" (Rs ${expense.totalAmount.toStringAsFixed(0)})?',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white),
            onPressed: () async {
              final verified = await SecurityVerificationModal.verify(
                ctx,
                title: 'Authorize Expense Deletion',
                subtitle: 'Scan fingerprint or enter PIN to delete shared expense',
              );
              if (!verified || !mounted) return;
              Provider.of<SplitProvider>(context, listen: false).deleteSplitExpense(expense.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense "${expense.title}" deleted.'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSubmitProofDialog({
    required String expenseId,
    required String expenseTitle,
    required String creditorName,
    required double amount,
    required String userId,
  }) {
    final tidController = TextEditingController();
    String method = 'Easypaisa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Submit 1-Click TID Proof',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settling share for "$expenseTitle":',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Text(
                'Rs ${amount.toStringAsFixed(0)} owed to $creditorName',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEmerald,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: ['Easypaisa', 'JazzCash', 'Bank Transfer', 'Cash'].map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => method = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tidController,
                decoration: const InputDecoration(
                  hintText: 'Transaction ID (e.g. EP-9831772)',
                  prefixIcon: Icon(Icons.receipt_rounded, color: AppColors.deepEmerald),
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
              onPressed: () {
                final tid = tidController.text.trim();
                if (tid.isNotEmpty) {
                  Provider.of<SplitProvider>(context, listen: false).submitProof(
                    expenseId: expenseId,
                    userId: userId,
                    transactionId: tid,
                    paymentMethod: method,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Proof TID $tid submitted for verification!'),
                      backgroundColor: AppColors.deepEmerald,
                    ),
                  );
                }
              },
              child: const Text('Submit Proof'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewProofDialog({
    required SplitExpenseModel expense,
    required SplitMemberShare share,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Review Settlement Proof',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${share.name} claims payment for "${expense.title}":',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightEmerald,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Claimed:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                      Text('Rs ${share.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepEmerald)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Method:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                      Text(share.paymentMethod ?? 'Easypaisa',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaction ID:', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                      Text(
                        share.proofTid ?? 'None',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.teal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Verify against your wallet/bank SMS statement before confirming.',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<SplitProvider>(context, listen: false).verifyProof(
                expenseId: expense.id,
                userId: share.userId,
                approve: false,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment marked as rejected/unpaid.'), backgroundColor: AppColors.errorRed),
              );
            },
            child: const Text('Reject', style: TextStyle(color: AppColors.errorRed)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepEmerald, foregroundColor: Colors.white),
            onPressed: () {
              Provider.of<SplitProvider>(context, listen: false).verifyProof(
                expenseId: expense.id,
                userId: share.userId,
                approve: true,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment verified and marked Settled!'), backgroundColor: AppColors.deepEmerald),
              );
            },
            child: const Text('1-Click Verify'),
          ),
        ],
      ),
    );
  }

  void _showGroupMembersDialog(GroupModel initialGroup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Consumer<SplitProvider>(
          builder: (context, splitProvider, _) {
            final group = splitProvider.groups.firstWhere(
              (g) => g.id == initialGroup.id,
              orElse: () => initialGroup,
            );

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkInk,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.category} • ${group.members.length} Members',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Invite Code Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.mutedGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.mutedGold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Invite Code',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                                ),
                                Text(
                                  group.inviteCode.isNotEmpty ? group.inviteCode : 'RAQ-GRP',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppColors.darkInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.deepEmerald),
                            tooltip: 'Copy Invite Code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: group.inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Invite code "${group.inviteCode}" copied to clipboard!'),
                                  backgroundColor: AppColors.deepEmerald,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Roommate Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.deepEmerald),
                        label: Text(
                          '+ Add Roommate by Email',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.deepEmerald),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.deepEmerald, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAddMemberDialog(group),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Group Members',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkInk,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Members List
                    ...group.members.map((m) {
                      final isAdmin = m.role.toLowerCase() == 'admin';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isAdmin ? AppColors.deepEmerald : AppColors.lightEmerald,
                              child: Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isAdmin ? Colors.white : AppColors.deepEmerald,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          m.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkInk,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isAdmin ? AppColors.deepEmerald.withValues(alpha: 0.12) : AppColors.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          m.role,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isAdmin ? AppColors.deepEmerald : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (m.email.isNotEmpty)
                                    Text(
                                      m.email,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (!isAdmin)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.errorRed, size: 20),
                                tooltip: 'Remove from Group',
                                onPressed: () => _confirmRemoveMember(group, m),
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Delete Group Option
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed, size: 18),
                        label: Text(
                          'Delete This Group',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.errorRed),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _showDeleteGroupDialog(group);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMemberDialog(GroupModel group) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_add_rounded, color: AppColors.deepEmerald),
            const SizedBox(width: 8),
            Text(
              'Add Roommate',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your roommate\'s registered email address to link them to "${group.name}".',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'roommate@gmail.com',
                labelText: 'Roommate Email',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.deepEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Ali (Optional)',
                labelText: 'Display Name (Optional)',
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.deepEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              final result = await Provider.of<SplitProvider>(context, listen: false).addMemberToGroup(
                group.id,
                email,
                fallbackName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Roommate added!'),
                  backgroundColor: (result['success'] == true) ? AppColors.deepEmerald : AppColors.errorRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Add Member', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(GroupModel group, GroupMember member) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Member?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove "${member.name}" from ${group.name}?',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await Provider.of<SplitProvider>(context, listen: false)
                  .removeMemberFromGroup(group.id, member.userId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Member "${member.name}" removed.' : 'Failed to remove member.'),
                  backgroundColor: success ? AppColors.darkInk : AppColors.errorRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    final splitProvider = Provider.of<SplitProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isMasked = authProvider.isPrivacyMasked;
    final currentUserId = authProvider.currentUser?.id ?? 'demo_user_101';
    final groups = splitProvider.groups;
    final allExpenses = splitProvider.groupExpenses;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'SplitVault',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkInk,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Join with Code',
            icon: const Icon(Icons.vpn_key_rounded, color: AppColors.deepEmerald),
            onPressed: _showJoinGroupDialog,
          ),
          IconButton(
            tooltip: 'New Group',
            icon: const Icon(Icons.group_add_rounded, color: AppColors.deepEmerald),
            onPressed: _showCreateGroupDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.deepEmerald,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.deepEmerald,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            const Tab(text: 'MY Balance'),
            Tab(text: 'Groups (${groups.length})'),
            Tab(text: 'Activity & Proofs (${allExpenses.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyBalanceTab(splitProvider, currentUserId, isMasked),
          _buildGroupsTab(groups),
          _buildActivityTab(splitProvider, currentUserId, isMasked),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: MY BALANCE (4 Analytics Cards + Auto-Netted Debts + Recent preview)
  // =========================================================================
  Widget _buildMyBalanceTab(SplitProvider splitProvider, String currentUserId, bool isMasked) {
    final debts = splitProvider.getDebtsForUser(currentUserId);
    final allExpenses = splitProvider.groupExpenses;
    final pendingVerifications = splitProvider.getPendingVerificationsForCreditor(currentUserId);

    final double amountYouOwe = debts
        .where((d) => d.fromUserId == currentUserId)
        .fold(0.0, (sum, d) => sum + d.netAmount);

    final double amountYoureOwed = debts
        .where((d) => d.toUserId == currentUserId)
        .fold(0.0, (sum, d) => sum + d.netAmount);

    return RefreshIndicator(
      onRefresh: () => splitProvider.fetchGroupsAndData(),
      color: AppColors.deepEmerald,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4 Analytics Stat Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                // 1. Active Groups — WHITE CARD
                _buildStatCard(
                  title: 'Active Groups',
                  value: '${splitProvider.activeGroupsCount}',
                  subtitle: 'Total groups you belong to',
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF0B3D34),
                  isDark: false,
                ),
                // 2. Total Shared Spend — DARK EMERALD CARD
                _buildStatCard(
                  title: 'Total Shared Spend',
                  value: CurrencyFormatter.format(splitProvider.totalSharedSpend, isMasked: isMasked),
                  subtitle: 'All shared expenses',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF16C79A),
                  isDark: true,
                ),
                // 3. Amount You Owe — DARK EMERALD CARD
                _buildStatCard(
                  title: 'Amount You Owe',
                  value: CurrencyFormatter.format(amountYouOwe, isMasked: isMasked),
                  subtitle: '${debts.where((d) => d.fromUserId == currentUserId).length} net debts due',
                  icon: Icons.arrow_outward_rounded,
                  iconColor: const Color(0xFFD4AF6B), // Muted gold for payable context
                  isDark: true,
                ),
                // 4. Amount You're Owed — WHITE CARD
                _buildStatCard(
                  title: "Amount You're Owed",
                  value: CurrencyFormatter.format(amountYoureOwed, isMasked: isMasked),
                  subtitle: '${pendingVerifications.length} proofs to approve',
                  icon: Icons.south_west_rounded,
                  iconColor: const Color(0xFF16C79A), // Subtle teal for receivable indicator
                  isDark: false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Simplified Net Balances Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.balance_rounded, color: AppColors.deepEmerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Simplified Net Balances',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkInk,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightEmerald,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Auto-Netted',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEmerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Net Debts List
            if (debts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.successGreen),
                      const SizedBox(height: 8),
                      Text(
                        'All balances are settled! 🎉',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.darkInk),
                      ),
                      Text(
                        'No outstanding pairwise debts among roommates.',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: debts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final debt = debts[i];
                  final isDebtor = debt.fromUserId == currentUserId;
                  final isCreditor = debt.toUserId == currentUserId;

                  // Check if there is an under-review proof submitted
                  final hasUnderReview = splitProvider.groupExpenses.any(
                    (e) => e.splits.any((s) => s.userId == debt.fromUserId && s.status == 'UnderReview'),
                  );

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDebtor
                          ? const Color(0xFFFFFBEB)
                          : (isCreditor ? const Color(0xFFF0FDF4) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDebtor
                            ? AppColors.pendingOrange.withValues(alpha: 0.3)
                            : (isCreditor ? AppColors.successGreen.withValues(alpha: 0.3) : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar initial
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDebtor
                              ? AppColors.pendingOrange.withValues(alpha: 0.2)
                              : AppColors.successGreen.withValues(alpha: 0.2),
                          child: Text(
                            (isDebtor ? debt.toUserName : debt.fromUserName).isNotEmpty
                                ? (isDebtor ? debt.toUserName : debt.fromUserName)[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: isDebtor ? AppColors.pendingOrange : AppColors.successGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Debt summary
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.outfit(fontSize: 14, color: AppColors.darkInk),
                                  children: [
                                    TextSpan(
                                      text: isDebtor ? 'You' : debt.fromUserName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isDebtor ? AppColors.pendingOrange : AppColors.darkInk,
                                      ),
                                    ),
                                    const TextSpan(text: ' owe '),
                                    TextSpan(
                                      text: isCreditor ? 'You' : debt.toUserName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isCreditor ? AppColors.successGreen : AppColors.darkInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                isDebtor ? 'You need to pay' : (isCreditor ? 'To be received' : 'Mutual balance'),
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),

                        // Amount & Actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(debt.netAmount, isMasked: isMasked),
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDebtor ? AppColors.pendingOrange : AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(height: 4),

                            if (isDebtor) ...[
                              if (hasUnderReview)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.pendingOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '⏳ Proof Submitted',
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.pendingOrange),
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final exp = splitProvider.groupExpenses.firstWhere(
                                      (e) => e.splits.any((s) => s.userId == currentUserId && s.status != 'Settled'),
                                      orElse: () => splitProvider.groupExpenses.first,
                                    );
                                    _showSubmitProofDialog(
                                      expenseId: exp.id,
                                      expenseTitle: exp.title,
                                      creditorName: debt.toUserName,
                                      amount: debt.netAmount,
                                      userId: currentUserId,
                                    );
                                  },
                                  icon: const Icon(Icons.bolt_rounded, size: 14),
                                  label: const Text('Settle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.deepEmerald,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    textStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                            ] else if (isCreditor) ...[
                              if (hasUnderReview)
                                ElevatedButton.icon(
                                  onPressed: () => _tabController.animateTo(2),
                                  icon: const Icon(Icons.shield_rounded, size: 14),
                                  label: const Text('Review'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.successGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    textStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gentle reminder sent to ${debt.fromUserName}!'),
                                        backgroundColor: AppColors.deepEmerald,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.notifications_active_rounded, size: 12),
                                  label: const Text('Remind'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.deepEmerald,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    textStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_rounded, color: AppColors.deepEmerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Activities',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkInk,
                      ),
                    ),
                  ],
                ),
                if (allExpenses.length > 3)
                  TextButton(
                    onPressed: () => _tabController.animateTo(2),
                    child: Text(
                      'View All (${allExpenses.length}) →',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepEmerald),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent 3 Expenses Preview
            if (allExpenses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Text(
                    'No shared expenses yet. Tap "Split Bill" to start!',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allExpenses.take(3).length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final exp = allExpenses[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.lightEmerald,
                          child: Icon(
                            _getCategoryIcon(exp.category),
                            color: AppColors.deepEmerald,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                'Paid by ${exp.paidByName} • ${DateFormat('d MMM').format(exp.date)}',
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(exp.totalAmount, isMasked: isMasked),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkInk,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: GROUPS (Group Cards with Delete, Member count, Invite Code & Copy)
  // =========================================================================
  Widget _buildGroupsTab(List<GroupModel> groups) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Living Groups Yet',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group for your hostel room, flat, or outing friends.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create First Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Groups',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkInk),
                  ),
                  Text(
                    'Manage groups, track member splits, and invite roommates',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final grp = groups[i];
              return _buildGroupCard(grp);
            },
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel grp) {
    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final groupExpenses = splitProvider.getExpensesForGroup(grp.id);
    final totalSpend = groupExpenses.fold<double>(0.0, (sum, e) => sum + e.totalAmount);

    int settledCount = 0;
    int totalSharesCount = 0;
    for (final exp in groupExpenses) {
      for (final s in exp.splits) {
        totalSharesCount++;
        if (s.status == 'Settled' || s.status == 'Verified') settledCount++;
      }
    }
    final progressPct = totalSharesCount > 0 ? ((settledCount / totalSharesCount) * 100).round() : 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, category & Delete Group Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightEmerald,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: AppColors.deepEmerald, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grp.name,
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkInk),
                      ),
                      Text(
                        grp.category,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                tooltip: 'Delete Group',
                onPressed: () => _showDeleteGroupDialog(grp),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badges: Member Count + Invite Code with 1-Click Copy
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${grp.members.length} members',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkInk),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: grp.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invite code "${grp.inviteCode}" copied to clipboard!'),
                      backgroundColor: AppColors.deepEmerald,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 13, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Text(
                        'Code: ${grp.inviteCode}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF6366F1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Spend Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Spend', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    'Rs ${totalSpend.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkInk),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Settled Ratio', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    '$progressPct% Settled',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.successGreen),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Settlement Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPct / 100.0,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Split Bill & Manage Group
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateSplitExpenseSheet(grp.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Split Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showGroupMembersDialog(grp),
                  icon: const Icon(Icons.people_rounded, size: 16),
                  label: const Text('Members'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepEmerald,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: ACTIVITY & PROOFS (Group Filter Scoping, Action Center, Shared Ledger)
  // =========================================================================
  Widget _buildActivityTab(SplitProvider splitProvider, String currentUserId, bool isMasked) {
    final groups = splitProvider.groups;
    final allExpenses = splitProvider.groupExpenses;

    // Filter strictly by the selected group (Resolves user request: "dosre group ke section main hi complete activities dekha rha ... keep everything seperate")
    final filteredExpenses = _selectedActivityGroupId == 'all'
        ? allExpenses
        : allExpenses.where((e) => e.groupId == _selectedActivityGroupId).toList();

    final pendingToVerify = splitProvider.getPendingVerificationsForCreditor(currentUserId);
    final pendingSubmitted = splitProvider.getPendingSubmittedProofsForDebtor(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Group Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('All Groups (${allExpenses.length})'),
                    selected: _selectedActivityGroupId == 'all',
                    onSelected: (_) => setState(() => _selectedActivityGroupId = 'all'),
                    selectedColor: AppColors.deepEmerald,
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: _selectedActivityGroupId == 'all' ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedActivityGroupId == 'all' ? Colors.white : AppColors.darkInk,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ...groups.map((g) {
                  final isSel = _selectedActivityGroupId == g.id;
                  final count = allExpenses.where((e) => e.groupId == g.id).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${g.name} ($count)'),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedActivityGroupId = g.id),
                      selectedColor: AppColors.deepEmerald,
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : AppColors.darkInk,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Action Center: Awaiting Your Approval (Creditor)
          if (pendingToVerify.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.successGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Awaiting Your Approval (${pendingToVerify.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...pendingToVerify.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.lightEmerald,
                            child: Text(
                              item.share.name.isNotEmpty ? item.share.name[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.deepEmerald),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.share.name} paid for "${item.expense.title}"',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'via ${item.share.paymentMethod ?? 'Easypaisa'} • TID: ${item.share.proofTid ?? 'Attached'}',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs ${item.share.amount.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.successGreen),
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () => _showReviewProofDialog(expense: item.expense, share: item.share),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: Text('Review →', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Action Center: Your Submitted Proofs Under Review (Debtor)
          if (pendingSubmitted.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pendingOrange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: AppColors.pendingOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Your Submitted Proofs Under Review (${pendingSubmitted.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pendingOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...pendingSubmitted.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: AppColors.pendingOrange, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paid to ${item.expense.paidByName} for "${item.expense.title}"',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'TID: ${item.share.proofTid ?? 'Attached'} • Waiting creditor approval',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.pendingOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Rs ${item.share.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pendingOrange),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Itemized Shared Expenses Ledger
          Text(
            'Itemized Shared Expenses (${filteredExpenses.length})',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkInk),
          ),
          const SizedBox(height: 10),

          if (filteredExpenses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Text(
                  'No expenses found for this group.',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredExpenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final exp = filteredExpenses[i];
                final isExpanded = _expandedExpenses[exp.id] ?? false;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      // Top Row
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedExpenses[exp.id] = !isExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.lightEmerald,
                                child: Icon(
                                  _getCategoryIcon(exp.category),
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
                                      exp.title,
                                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkInk),
                                    ),
                                    Text(
                                      '${exp.groupName.isNotEmpty ? exp.groupName : 'Group'} • Paid by ${exp.paidByName} • ${DateFormat('d MMM yyyy').format(exp.date)}',
                                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(exp.totalAmount, isMasked: isMasked),
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkInk),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorRed),
                                        onPressed: () => _showDeleteExpenseDialog(exp),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded Member Shares
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.all(14),
                          color: AppColors.surfaceSubtle.withValues(alpha: 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member Splits (${exp.splitType} Split):',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 8),
                              ...exp.splits.map((share) {
                                final isUserShare = share.userId == currentUserId;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: share.status == 'Settled' || share.status == 'Verified'
                                            ? AppColors.successGreen.withValues(alpha: 0.15)
                                            : AppColors.borderLight,
                                        child: Text(
                                          share.name.isNotEmpty ? share.name[0].toUpperCase() : '?',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: share.status == 'Settled' || share.status == 'Verified'
                                                ? AppColors.successGreen
                                                : AppColors.darkInk,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isUserShare ? '${share.name} (You)' : share.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: isUserShare ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Rs ${share.amount.toStringAsFixed(0)}',
                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(width: 10),
                                      _buildStatusBadge(share.status),
                                      if (isUserShare && share.status == 'Unpaid' && exp.paidByUserId != currentUserId) ...[
                                        const SizedBox(width: 6),
                                        ElevatedButton(
                                          onPressed: () => _showSubmitProofDialog(
                                            expenseId: exp.id,
                                            expenseTitle: exp.title,
                                            creditorName: exp.paidByName,
                                            amount: share.amount,
                                            userId: currentUserId,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.deepEmerald,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: Text('Pay', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  // Helper UI Widgets

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B3D34) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF0B3D34) : const Color(0xFFE2EAE5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF101817),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 17, color: iconColor),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0B3D34),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFB7D4C9) : const Color(0xFF61716D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    if (status == 'Settled' || status == 'Verified') {
      bg = AppColors.successGreen.withValues(alpha: 0.15);
      fg = AppColors.successGreen;
      label = 'Settled';
    } else if (status == 'UnderReview') {
      bg = AppColors.pendingOrange.withValues(alpha: 0.15);
      fg = AppColors.pendingOrange;
      label = 'Under Review';
    } else {
      bg = AppColors.surfaceSubtle;
      fg = AppColors.textMuted;
      label = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'utilities':
        return Icons.flash_on_rounded;
      case 'housing':
      case 'rent':
        return Icons.home_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'food':
      default:
        return Icons.restaurant_rounded;
    }
  }
}
