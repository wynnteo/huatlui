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

  // HuatLui palette: near-neutral surfaces with ONE cobalt-blue accent.
  // Orange belongs to ByeLui and teal to MyLui, so HuatLui gets blue.
  // The accent is used sparingly (primary actions, charts, selection);
  // everything else is neutral so the numbers do the talking.
  // gain/loss/warning stay conventional green/red/amber so returns read
  // correctly at a glance.
  static const light = AppColors(
    surface: Color(0xFFFAFAF8),
    surfaceRaised: Color(0xFFFFFFFF),
    outline: Color(0xFFE8E8E4),
    textPrimary: Color(0xFF121316),
    textSecondary: Color(0xFF5E6168),
    textTertiary: Color(0xFF9C9FA6),
    accent: Color(0xFF2F4FD6),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFF2F4FD6),
    gain: Color(0xFF1E8A5A),
    loss: Color(0xFFD0443A),
    warning: Color(0xFFC48A12),
  );

  static const dark = AppColors(
    surface: Color(0xFF0D0E10),
    surfaceRaised: Color(0xFF16171A),
    outline: Color(0xFF25272B),
    textPrimary: Color(0xFFF1F1F2),
    textSecondary: Color(0xFFA2A5AC),
    textTertiary: Color(0xFF6A6D74),
    accent: Color(0xFF7B97FF),
    onAccent: Color(0xFF0B0F24),
    accentText: Color(0xFF9DB2FF),
    gain: Color(0xFF4CC38A),
    loss: Color(0xFFF0776A),
    warning: Color(0xFFE8B44A),
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
