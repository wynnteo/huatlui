import 'package:flutter/material.dart';

/// All HuatLui design tokens, as instance fields on a ThemeExtension —
/// never `static const`. That's the whole trick: `context.colors.gain`
/// resolves through `Theme.of(context)` at build time, so flipping
/// ThemeMode repaints every screen automatically. No per-screen edits
/// needed when you add a theme later.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color surface; // page background
  final Color surfaceRaised; // cards / sheets
  final Color outline; // hairlines, borders

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color accent; // the one brand accent (fills — pair with onAccent)
  final Color onAccent; // text/icon color to use ON TOP of accent fills
  final Color accentText; // deepened variant for using accent AS text/icon color directly on surface

  final Color gain; // positive return / income
  final Color loss; // negative return / expense
  final Color warning; // near a threshold, not yet breached

  const AppColors({
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.gain,
    required this.loss,
    required this.warning,
  });

  // HuatLui palette: cool petrol-teal on a mint-tinted white (light) or
  // deep petrol-black (dark). Deliberately unlike ByeLui (cream + periwinkle)
  // and MyLui (orange/gold + cream). gain/loss/warning stay conventional
  // green/red/amber on purpose so returns read correctly at a glance.
  static const light = AppColors(
    surface: Color(0xFFF3F8F7),
    surfaceRaised: Color(0xFFFFFFFF),
    outline: Color(0xFFD5E3E0),
    textPrimary: Color(0xFF0F2A2B),
    textSecondary: Color(0xFF4A6567),
    textTertiary: Color(0xFF86A0A2),
    accent: Color(0xFF0B6E8A),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFF0B6E8A),
    gain: Color(0xFF2E8B57),
    loss: Color(0xFFD14B3F),
    warning: Color(0xFFD99A1E),
  );

  static const dark = AppColors(
    surface: Color(0xFF0A1517),
    surfaceRaised: Color(0xFF112226),
    outline: Color(0xFF1E3A40),
    textPrimary: Color(0xFFE3F0F0),
    textSecondary: Color(0xFF93B0B2),
    textTertiary: Color(0xFF5F7B7E),
    accent: Color(0xFF38B6D1),
    onAccent: Color(0xFF04181D),
    accentText: Color(0xFF6FD0E6),
    gain: Color(0xFF4CC38A),
    loss: Color(0xFFF0776A),
    warning: Color(0xFFF0B94A),
  );

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? gain,
    Color? loss,
    Color? warning,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      gain: gain ?? this.gain,
      loss: loss ?? this.loss,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

/// `context.colors.gain` instead of `Theme.of(context).extension<AppColors>()!.gain`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
