import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../theme/app_colors.dart';
import '../theme/chart_palette.dart';
import '../theme/app_theme.dart';

/// Small floating label used by the bar charts.
class _Bubble extends StatelessWidget {
  final List<String> lines;
  const _Bubble({required this.lines});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            Text(
              lines[i],
              style: i == 0 && lines.length == 2
                  ? TextStyle(fontSize: 10, color: c.textTertiary)
                  : AppTheme.numeral(context, size: 12, weight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}

/// One thin bar per month. Tap a bar (or drag across them) to read its exact
/// value; tap it again to dismiss. With nothing selected the latest month is
/// solid; with a selection, that bar is.
class MonthlyBars extends StatefulWidget {
  final List<MonthValue> data;
  final String Function(double) format;
  final double height;
  const MonthlyBars({super.key, required this.data, required this.format, this.height = 96});

  @override
  State<MonthlyBars> createState() => _MonthlyBarsState();
}

class _MonthlyBarsState extends State<MonthlyBars> {
  int? _sel;
  static const double _bubbleZone = 40;

  void _pick(double dx, double w, {bool toggle = false}) {
    final n = widget.data.length;
    if (n == 0 || w <= 0) return;
    final i = (dx / w * n).floor().clamp(0, n - 1).toInt();
    setState(() => _sel = (toggle && _sel == i) ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = widget.data;
    final n = data.length;
    final height = widget.height;
    final maxV = data.fold<double>(0, (m, e) => math.max(m, e.value));
    final sel = (_sel != null && _sel! < n) ? _sel : null;

    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _pick(d.localPosition.dx, w, toggle: true),
          onHorizontalDragStart: (d) => _pick(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, w),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  const SizedBox(height: _bubbleZone),
                  SizedBox(
                    height: height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < n; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: (maxV > 0 && data[i].value > 0) ? math.max(3.0, data[i].value / maxV * height) : 2.0,
                                  decoration: BoxDecoration(
                                    color: data[i].value > 0
                                        ? ((sel ?? n - 1) == i ? c.accent : c.accent.withOpacity(0.35))
                                        : c.outline,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final m in data)
                        Expanded(
                          child: Text('${m.month.month}', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: c.textTertiary)),
                        ),
                    ],
                  ),
                ],
              ),
              if (sel != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment(-1 + 2 * (sel + 0.5) / n, -1),
                    child: _Bubble(
                      lines: [
                        '${data[sel].month.year}-${data[sel].month.month.toString().padLeft(2, '0')}',
                        widget.format(data[sel].value),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A label, an amount, and a thin bar underneath showing its share of the
/// largest item in the list.
class BarRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String valueText;
  final double fraction; // 0..1
  final Color barColor;
  final Color? valueColor;

  const BarRow({
    super.key,
    required this.label,
    this.sublabel,
    required this.valueText,
    required this.fraction,
    required this.barColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = fraction.clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(sublabel ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textTertiary)),
              ),
              const SizedBox(width: 8),
              Text(valueText, style: AppTheme.numeral(context, size: 14, weight: FontWeight.w500, color: valueColor)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(height: 4, decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(2))),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: f,
                  child: Container(height: 4, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One slim stacked bar for a whole split (e.g. asset classes).
class StackedStrip extends StatelessWidget {
  final List<double> weights; // any positive numbers; shown proportionally
  const StackedStrip({super.key, required this.weights});

  /// Same colours as the donut chart, so a legend reads the same everywhere.
  static Color shade(BuildContext context, int index, int count) => ChartPalette.color(context, index);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (var i = 0; i < weights.length; i++)
              Expanded(
                flex: math.max(1, (weights[i] * 10).round()),
                child: Container(
                  margin: EdgeInsets.only(right: i == weights.length - 1 ? 0 : 2),
                  color: shade(context, i, weights.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The selected year against the year before, month by month: last year
/// faded, this year solid. Tap or drag across the months to read both values.
class YoYBars extends StatefulWidget {
  final List<double> thisYear;
  final List<double> lastYear;
  final int year;
  final String Function(double) format;
  final double height;
  const YoYBars({super.key, required this.thisYear, required this.lastYear, required this.year, required this.format, this.height = 110});

  @override
  State<YoYBars> createState() => _YoYBarsState();
}

class _YoYBarsState extends State<YoYBars> {
  int? _sel;
  static const double _bubbleZone = 56;

  void _pick(double dx, double w, {bool toggle = false}) {
    if (w <= 0) return;
    final i = (dx / w * 12).floor().clamp(0, 11).toInt();
    setState(() => _sel = (toggle && _sel == i) ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = widget.height;
    var maxV = 0.0;
    for (var i = 0; i < 12; i++) {
      maxV = math.max(maxV, math.max(widget.thisYear[i], widget.lastYear[i]));
    }

    Widget bar(double v, Color color) {
      final h = (maxV > 0 && v > 0) ? math.max(3.0, v / maxV * height) : 0.0;
      return Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ),
      );
    }

    Widget legend(Color color, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(fontSize: 11, color: c.textSecondary)),
          ],
        );

    final sel = _sel;
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _pick(d.localPosition.dx, w, toggle: true),
          onHorizontalDragStart: (d) => _pick(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, w),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _bubbleZone),
                  SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        Align(alignment: Alignment.bottomCenter, child: Container(height: 1, color: c.outline)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < 12; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Opacity(
                                    opacity: (sel == null || sel == i) ? 1 : 0.45,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        bar(widget.lastYear[i], c.accent.withOpacity(0.3)),
                                        const SizedBox(width: 2),
                                        bar(widget.thisYear[i], c.accent),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 1; i <= 12; i++)
                        Expanded(child: Text('$i', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: c.textTertiary))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      legend(c.accent.withOpacity(0.3), '${widget.year - 1}'),
                      const SizedBox(width: 16),
                      legend(c.accent, '${widget.year}'),
                    ],
                  ),
                ],
              ),
              if (sel != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment(-1 + 2 * (sel + 0.5) / 12, -1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.surfaceRaised,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.outline),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.year}  ${widget.format(widget.thisYear[sel])}', style: AppTheme.numeral(context, size: 12, weight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('${widget.year - 1}  ${widget.format(widget.lastYear[sel])}',
                              style: AppTheme.numeral(context, size: 12, weight: FontWeight.w400, color: c.textTertiary)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
