import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Colours for charts with several series (donut, legend dots, the stacked
/// strip). The first is always the brand accent; the rest are the same
/// colour turned around the hue wheel and muted, so changing the accent in
/// AppColors re-colours every chart automatically.
class ChartPalette {
  static Color color(BuildContext context, int index) {
    final accent = context.colors.accent;
    if (index == 0) return accent;
    final hsl = HSLColor.fromColor(accent);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HSLColor.fromAHSL(1, (hsl.hue + index * 47) % 360, 0.40, dark ? 0.64 : 0.55).toColor();
  }
}
