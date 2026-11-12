import 'package:flutter/material.dart';

/// Raqmify Brand Identity & Palette (As per formal Project Proposal)
class AppColors {
  // Brand Anchors
  static const Color deepEmerald = Color(0xFF0B3D34);
  static const Color teal = Color(0xFF16C79A);
  static const Color mutedGold = Color(0xFFD4AF6B);
  static const Color offWhite = Color(0xFFF7F8F6);
  static const Color darkInk = Color(0xFF101817);

  // Surface & Neutrals
  static const Color cardWhite = Colors.white;
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFEDF2F0);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color surfaceSubtle = Color(0xFFF0F4F2);
  static const Color lightEmerald = Color(0xFFE8F5F2);

  // Semantic Status Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color pendingOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF0B3D34), Color(0xFF115E59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF6B), Color(0xFFB89247)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF16C79A), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
