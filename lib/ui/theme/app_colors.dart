import 'package:flutter/material.dart';

/// Extensão de cores de tema baseada nas paletas personalizadas do CheckList (Claro e Escuro).
///
/// Propriedades fornecidas:
/// - [primary]: #4caf50 (Verde principal)
/// - [primaryBg]: #e8f5e9 (Claro) / #0d2010 (Escuro)
/// - [gridHoverBg]: #f1f8e9 (Claro) / #0d2215 (Escuro)
/// - [border]: #e2e8f0 (Claro) / #1f2937 (Escuro)
/// - [surface]: #ffffff (Claro) / #161b27 (Escuro)
/// - [sidebarBg]: #f8fafc (Claro) / #131a24 (Escuro)
/// - [sidebarTextMuted]: #64748b (Ambos)
/// - [primaryPressed]: #388e3c (Ambos)
/// - [textPrimary]: #0f172a (Claro) / #e2e8f0 (Escuro)
/// - [textSecondary]: #475569 (Claro) / #94a3b8 (Escuro)
/// - [cardBg]: rgba(255, 255, 255, 0.7) (Claro) / rgba(22, 27, 39, 0.2) (Escuro)
/// - [cardBlur]: 4.0
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryBg;
  final Color gridHoverBg;
  final Color border;
  final Color surface;
  final Color sidebarBg;
  final Color sidebarTextMuted;
  final Color primaryPressed;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final double cardBlur;

  const AppColorsExtension({
    required this.primary,
    required this.primaryBg,
    required this.gridHoverBg,
    required this.border,
    required this.surface,
    required this.sidebarBg,
    required this.sidebarTextMuted,
    required this.primaryPressed,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBlur,
  });

  /// Paleta do Tema Claro
  static const light = AppColorsExtension(
    primary: Color(0xFF4CAF50),
    primaryBg: Color(0xFFE8F5E9),
    gridHoverBg: Color(0xFFF1F8E9),
    border: Color(0xFFE2E8F0),
    surface: Color(0xFFFFFFFF),
    sidebarBg: Color(0xFFF8FAFC),
    sidebarTextMuted: Color(0xFF64748B),
    primaryPressed: Color(0xFF388E3C),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    cardBg: Color(0xB3FFFFFF), // rgba(255, 255, 255, 0.7)
    cardBlur: 4.0,
  );

  /// Paleta do Tema Escuro
  static const dark = AppColorsExtension(
    primary: Color(0xFF4CAF50),
    primaryBg: Color(0xFF0D2010),
    gridHoverBg: Color(0xFF0D2215),
    border: Color(0xFF1F2937),
    surface: Color(0xFF161B27),
    sidebarBg: Color(0xFF131A24),
    sidebarTextMuted: Color(0xFF64748B),
    primaryPressed: Color(0xFF388E3C),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    cardBg: Color(0x33161B27), // rgba(22, 27, 39, 0.2)
    cardBlur: 4.0,
  );

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryBg,
    Color? gridHoverBg,
    Color? border,
    Color? surface,
    Color? sidebarBg,
    Color? sidebarTextMuted,
    Color? primaryPressed,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBg,
    double? cardBlur,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryBg: primaryBg ?? this.primaryBg,
      gridHoverBg: gridHoverBg ?? this.gridHoverBg,
      border: border ?? this.border,
      surface: surface ?? this.surface,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      sidebarTextMuted: sidebarTextMuted ?? this.sidebarTextMuted,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      cardBg: cardBg ?? this.cardBg,
      cardBlur: cardBlur ?? this.cardBlur,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryBg: Color.lerp(primaryBg, other.primaryBg, t) ?? primaryBg,
      gridHoverBg: Color.lerp(gridHoverBg, other.gridHoverBg, t) ?? gridHoverBg,
      border: Color.lerp(border, other.border, t) ?? border,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t) ?? sidebarBg,
      sidebarTextMuted:
          Color.lerp(sidebarTextMuted, other.sidebarTextMuted, t) ??
              sidebarTextMuted,
      primaryPressed:
          Color.lerp(primaryPressed, other.primaryPressed, t) ?? primaryPressed,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      cardBg: Color.lerp(cardBg, other.cardBg, t) ?? cardBg,
      cardBlur: cardBlur + (other.cardBlur - cardBlur) * t,
    );
  }
}

/// Extensão no BuildContext para acesso rápido e direto às cores da paleta.
extension AppColorsContextExtension on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;

  bool get isDarkMode =>
      Theme.of(this).brightness == Brightness.dark;
}
