import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/split_provider.dart';
import '../../auth/login_screen.dart';
import '../../auth/widgets/security_verification_modal.dart';
import 'compact_account_dropdown.dart';
import 'notifications_sheet.dart';

class DashboardHeader extends StatefulWidget {
  final UserModel? user;
  final bool hasUnreadNotifications;
  final int unreadCount;
  final VoidCallback onProfileTap;

  const DashboardHeader({
    super.key,
    required this.user,
    required this.hasUnreadNotifications,
    required this.unreadCount,
    required this.onProfileTap,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with SingleTickerProviderStateMixin {
  final GlobalKey _profileKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openDropdown() {
    _closeDropdown();
    final overlay = Overlay.of(context);
    final renderBox = _profileKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    const dropdownWidth = 224.0;
    double right = screenWidth - (offset.dx + size.width);
    if (right < 16.0) right = 16.0;
    if (right + dropdownWidth > screenWidth - 16.0) {
      right = 16.0;
    }
    final top = offset.dy + size.height + 6;

    _animController.forward(from: 0.0);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDropdown,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: top,
            right: right,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.transparent,
                  child: CompactAccountDropdown(
                    user: widget.user,
                    onMyProfile: () {
                      _closeDropdown();
                      widget.onProfileTap();
                    },
                    onAccountSettings: () {
                      _closeDropdown();
                      widget.onProfileTap();
                    },
                    onPrivacyVault: () async {
                      _closeDropdown();
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (auth.isPrivacyMasked) {
                        final verified = await SecurityVerificationModal.verify(
                          context,
                          title: 'Unlock Privacy Vault',
                          subtitle: 'Enter PIN or scan fingerprint to reveal balance',
                        );
                        if (verified) {
                          await auth.togglePrivacyMask(force: true);
                        }
                      } else {
                        await auth.togglePrivacyMask();
                      }
                    },
                    onNotifications: () {
                      _closeDropdown();
                      NotificationsSheet.show(context);
                    },
                    onHelpSupport: () {
                      _closeDropdown();
                      _showHelpSupportDialog(context);
                    },
                    onLogout: () {
                      _closeDropdown();
                      _handleLogout(context);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.deepEmerald, size: 22),
            const SizedBox(width: 8),
            Text('Help & Support', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance with your Raqmify wallet or SplitVault balances?',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2EAE5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Support Email:',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'support@raqmify.com',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepEmerald),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Raqmify Mobile v1.0.0 (Production Release)\nDesigned for high security and transparent financial tracking.',
              style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to log out of your Raqmify account?',
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textMuted),
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final expProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final splitProvider = Provider.of<SplitProvider>(context, listen: false);
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      expProvider.clearData();
      splitProvider.clearData();
      notifProvider.clearData();
      await notifProvider.setActiveUser(null);
      await auth.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fullName = widget.user?.name.trim() ?? 'User';
    final firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'User';

    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      children: [
        // 1. Dashboard Top Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Side - Raqmify Branding (Logo + Wordmark)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/raqmify_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  'Raqmify',
                  style: GoogleFonts.outfit(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0B3D34),
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),

            // Right Side - Header Actions (Notification Bell + Profile Button)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Notification Bell Icon (Deep Emerald)
                InkWell(
                  onTap: () => NotificationsSheet.show(context),
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : const Color(0xFFE2EAE5),
                              ),
                            ),
                            child: Icon(
                              AppIcons.notification,
                              size: 19,
                              color: isDark ? Colors.white : const Color(0xFF0B3D34),
                            ),
                          ),
                          if (widget.hasUnreadNotifications)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    '${widget.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Circular user profile/avatar button (Soft Sage #E7F1EC background)
                InkWell(
                  key: _profileKey,
                  onTap: _toggleDropdown,
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F1EC), // Soft Sage
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2EAE5),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B3D34), // Deep Emerald
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 2. Dashboard Greeting Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greetingPrefix, $firstName!',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF101817),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Here's your financial overview.",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9EABA7) : const Color(0xFF61716D),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2EAE5),
                ),
              ),
              child: Text(
                DateFormat('MMM yyyy').format(DateTime.now()),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.teal : const Color(0xFF0B3D34),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
