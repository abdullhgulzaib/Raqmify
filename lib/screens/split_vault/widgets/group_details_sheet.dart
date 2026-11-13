import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/group_model.dart';
import '../../../providers/split_provider.dart';
import '../../auth/widgets/security_verification_modal.dart';

class GroupDetailsSheet extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const GroupDetailsSheet({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  static Future<void> show(
    BuildContext context, {
    required GroupModel group,
    required String currentUserId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupDetailsSheet(
        group: group,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  State<GroupDetailsSheet> createState() => _GroupDetailsSheetState();
}

class _GroupDetailsSheetState extends State<GroupDetailsSheet> {
  late GroupModel _group;
  final TextEditingController _emailController = TextEditingController();
  bool _isAddingMember = false;
  String? _memberError;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isCreator =>
      _group.createdBy == widget.currentUserId ||
      _group.members.any(
        (m) => m.userId == widget.currentUserId && m.role == 'Admin',
      );

  Future<void> _handleAddMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _memberError = "Please enter roommate's registered email address.");
      return;
    }

    setState(() {
      _isAddingMember = true;
      _memberError = null;
    });

    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final result = await splitProvider.addMemberToGroup(_group.id, email);

    if (!mounted) return;
    setState(() => _isAddingMember = false);

    if (result.isSuccess && result.dataOrNull != null) {
      _emailController.clear();
      setState(() {
        _group = result.dataOrNull!;
        _memberError = null;
      });
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Roommate linked to group successfully!'),
          backgroundColor: AppColors.deepEmerald,
        ),
      );
    } else {
      setState(() {
        _memberError = result.failureOrNull?.message ?? 'Could not add member';
      });
    }
  }

  Future<void> _handleRemoveMember(GroupMember member) async {
    final isSelf = member.userId == widget.currentUserId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isSelf ? 'Leave Group' : 'Remove Member',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isSelf
              ? 'Are you sure you want to leave "${_group.name}"?'
              : 'Are you sure you want to remove "${member.name}" from "${_group.name}"?',
          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isSelf ? 'Leave Group' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final result = await splitProvider.removeMemberFromGroup(_group.id, member.userId);

    if (!mounted) return;

    if (result.isSuccess) {
      if (isSelf) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have left "${_group.name}".'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      } else {
        if (result.dataOrNull != null) {
          setState(() => _group = result.dataOrNull!);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${member.name}" removed from group.'),
            backgroundColor: AppColors.deepEmerald,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Could not remove member'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _handleDeleteGroup() async {
    final verified = await SecurityVerificationModal.verify(
      context,
      title: 'Authorize Group Deletion',
      subtitle: 'Scan fingerprint or enter PIN to delete group',
    );

    if (!verified || !mounted) return;

    final splitProvider = Provider.of<SplitProvider>(context, listen: false);
    final result = await splitProvider.deleteGroup(_group.id);

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${_group.name}" deleted.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Could not delete group'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF141E1C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkInk;
    final containerBg = isDark ? const Color(0xFF1E2826) : AppColors.surfaceSubtle;
    final borderColor = isDark ? const Color(0xFF2C3E38) : const Color(0xFFE2EAE5);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _group.name,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A3831) : AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _group.category,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_group.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _group.description,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              children: [
                // 1. Group Invite Code Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: containerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group Invite Code',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _group.inviteCode,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: isDark ? const Color(0xFF68D391) : AppColors.deepEmerald,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _group.inviteCode));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invite code "${_group.inviteCode}" copied to clipboard!'),
                              backgroundColor: AppColors.deepEmerald,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, color: AppColors.deepEmerald, size: 20),
                        tooltip: 'Copy Code',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Add Roommate / Link Member Form (Complete Web Scenario)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2624) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.deepEmerald),
                          const SizedBox(width: 8),
                          Text(
                            'Link Roommate to Group',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.outfit(fontSize: 13, color: textColor),
                              decoration: InputDecoration(
                                hintText: 'roommate@gmail.com',
                                hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 16, color: AppColors.deepEmerald),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                filled: true,
                                fillColor: containerBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.deepEmerald),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isAddingMember ? null : _handleAddMember,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepEmerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _isAddingMember
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Link',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                          ),
                        ],
                      ),
                      if (_memberError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _memberError!,
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.errorRed),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Precaution: Your roommate must already have a registered account with this email to link them.',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Roommates List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Roommates & Members (${_group.members.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Members List View
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _group.members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final m = _group.members[idx];
                    final isThisUser = m.userId == widget.currentUserId;
                    final isCreatorMember = m.userId == _group.createdBy;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: containerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: isThisUser
                                ? AppColors.deepEmerald
                                : AppColors.deepEmerald.withValues(alpha: 0.15),
                            child: Text(
                              m.name.isNotEmpty ? m.name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isThisUser ? Colors.white : AppColors.deepEmerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.name}${isThisUser ? ' (You)' : ''}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (m.email.isNotEmpty)
                                  Text(
                                    m.email,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCreatorMember
                                  ? (isDark ? const Color(0xFF1A3831) : AppColors.lightEmerald)
                                  : (isDark ? Colors.black26 : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCreatorMember ? 'Creator' : m.role,
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isCreatorMember
                                    ? (isDark ? const Color(0xFF68D391) : AppColors.deepEmerald)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),

                          // Action: Remove Member (if Admin and not creator) or Leave Group (if self and not creator)
                          if (_isCreator && !isThisUser && !isCreatorMember) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                              tooltip: 'Remove member',
                              onPressed: () => _handleRemoveMember(m),
                            ),
                          ] else if (!isCreatorMember && isThisUser) ...[
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => _handleRemoveMember(m),
                              icon: const Icon(Icons.logout_rounded, size: 14, color: AppColors.errorRed),
                              label: Text(
                                'Leave',
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.errorRed),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 4. Delete Group Option (Creator only)
                if (_isCreator)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        'Delete Living Group',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _handleDeleteGroup,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
