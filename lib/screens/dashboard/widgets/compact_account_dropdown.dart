import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';

class CompactAccountDropdown extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onMyProfile;
  final VoidCallback onAccountSettings;
  final VoidCallback onPrivacyVault;
  final VoidCallback onNotifications;
  final VoidCallback onHelpSupport;
  final VoidCallback onLogout;

  const CompactAccountDropdown({
    super.key,
    required this.user,
    required this.onMyProfile,
    required this.onAccountSettings,
    required this.onPrivacyVault,
    required this.onNotifications,
    required this.onHelpSupport,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = user?.name.trim() ?? 'User';
    final email = user?.email.trim() ?? 'user@raqmify.com';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final bg = isDark ? const Color(0xFF1B2623) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B3A36) : const Color(0xFFE2EAE5);
    final textNameColor = isDark ? Colors.white : const Color(0xFF101817);
    final textEmailColor = isDark ? const Color(0xFF9EABA7) : const Color(0xFF61716D);

    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Compact Account Information Row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F1EC), // Soft Sage
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B3D34), // Deep Emerald
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textNameColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: textEmailColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: borderColor),
          const SizedBox(height: 4),

          // B. Vertical Menu Column (6 items)
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            label: 'My Profile',
            iconColor: AppColors.deepEmerald,
            textColor: textNameColor,
            isDark: isDark,
            onTap: onMyProfile,
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            label: 'Account Settings',
            iconColor: AppColors.deepEmerald,
            textColor: textNameColor,
            isDark: isDark,
            onTap: onAccountSettings,
          ),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            label: 'Privacy Vault',
            iconColor: AppColors.deepEmerald,
            textColor: textNameColor,
            isDark: isDark,
            onTap: onPrivacyVault,
          ),
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            iconColor: AppColors.deepEmerald,
            textColor: textNameColor,
            isDark: isDark,
            onTap: onNotifications,
          ),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            iconColor: AppColors.deepEmerald,
            textColor: textNameColor,
            isDark: isDark,
            onTap: onHelpSupport,
          ),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            iconColor: const Color(0xFFE53E3E), // Muted red
            textColor: const Color(0xFFE53E3E),
            isDark: isDark,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0xFFE7F1EC).withValues(alpha: 0.3),
      splashColor: const Color(0xFFE7F1EC).withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
        child: Row(
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
