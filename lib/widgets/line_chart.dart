import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'currency_display.dart';
import 'ui_helpers.dart';

/// Portfolio value (solid line) against what it cost (dashed line).
/// Press and drag across it to read any day; let go and it returns to today.
class PortfolioLineChart extends StatefulWidget {
  final List<SeriesPoint> data;
  final String base;
  final String valueLabel;
  final String costLabel;
  final double height;

  const PortfolioLineChart({
    super.key,
    required this.data,
    required this.base,
    required this.valueLabel,
    required this.costLabel,
    this.height = 190,
  });

  @override
  State<PortfolioLineChart> createState() => _PortfolioLineChartState();
}

class _PortfolioLineChartState extends State<PortfolioLineChart> {
  int? _sel;

  void _select(double dx, double width) {
    final n = widget.data.length;
    if (n < 2 || width <= 0) return;
    final i = ((dx / width) * (n - 1)).round().clamp(0, n - 1).toInt();
    if (i != _sel) setState(() => _sel = i);
  }

  void _clear() {
    if (_sel != null) setState(() => _sel = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = widget.data;
    final n = data.length;
    final idx = (_sel != null && _sel! < n) ? _sel! : n - 1;
    final p = data[idx];
    final gainColor = signColor(context, p.gain);
    final pct = '${p.gainPct > 0 ? '+' : ''}${p.gainPct.toStringAsFixed(2)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            CurrencyText.formatAmount(p.value, widget.base),
            style: AppTheme.numeral(context, size: 30, weight: FontWeight.w600).copyWith(letterSpacing: -0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(CurrencyText.formatSigned(p.gain, widget.base), style: AppTheme.numeral(context, size: 13, color: gainColor)),
            Text(pct, style: AppTheme.numeral(context, size: 13, weight: FontWeight.w500, color: gainColor)),
            Text(fmtDate(p.date), style: TextStyle(fontSize: 12, color: c.textTertiary)),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, cons) {
            final w = cons.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _select(d.localPosition.dx, w),
              onTapUp: (_) => _clear(),
              onTapCancel: _clear,
              onHorizontalDragStart: (d) => _select(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) => _select(d.localPosition.dx, w),
              onHorizontalDragEnd: (_) => _clear(),
              onHorizontalDragCancel: _clear,
              child: SizedBox(
                height: widget.height,
                width: w,
                child: CustomPaint(
                  painter: _LinePainter(
                    data: data,
                    selected: _sel != null && _sel! < n ? _sel : null,
                    lineColor: c.accent,
                    costColor: c.textTertiary,
                    gridColor: c.outline,
                    labelColor: c.textTertiary,
                    ringColor: c.surface,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(width: 14, height: 2, color: c.accent),
            const SizedBox(width: 6),
            Text(widget.valueLabel, style: TextStyle(fontSize: 11, color: c.textSecondary)),
            const SizedBox(width: 16),
            SizedBox(
              width: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 5, height: 2, color: c.textTertiary),
                  Container(width: 5, height: 2, color: c.textTertiary),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(widget.costLabel, style: TextStyle(fontSize: 11, color: c.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<SeriesPoint> data;
  final int? selected;
  final Color lineColor;
  final Color costColor;
  final Color gridColor;
  final Color labelColor;
  final Color ringColor;

  static const double _bottomPad = 22;

  _LinePainter({
    required this.data,
    required this.selected,
    required this.lineColor,
    required this.costColor,
    required this.gridColor,
    required this.labelColor,
    required this.ringColor,
  });

  void _dashed(Canvas canvas, Path path, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  void _label(Canvas canvas, String text, double x, double y, {required TextAlign align}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 10, color: labelColor)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == TextAlign.left ? x : (align == TextAlign.right ? x - tp.width : x - tp.width / 2);
    tp.paint(canvas, Offset(dx, y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final w = size.width;
    final h = size.height - _bottomPad;

    var minV = double.infinity;
    var maxV = -double.infinity;
    for (final p in data) {
      minV = math.min(minV, math.min(p.value, p.invested));
      maxV = math.max(maxV, math.max(p.value, p.invested));
    }
    if (maxV - minV < 1e-9) maxV = minV + 1;
    final pad = (maxV - minV) * 0.12;
    minV -= pad;
    maxV += pad;

    double x(int i) => w * i / (data.length - 1);
    double y(double v) => h - (v - minV) / (maxV - minV) * h;

    // Three quiet gridlines.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final gy = h * i / 2;
      canvas.drawLine(Offset(0, gy), Offset(w, gy), grid);
    }

    // Value line + soft fill beneath it.
    final valuePath = Path()..moveTo(x(0), y(data.first.value));
    for (var i = 1; i < data.length; i++) {
      valuePath.lineTo(x(i), y(data[i].value));
    }
    final fill = Path.from(valuePath)
      ..lineTo(x(data.length - 1), h)
      ..lineTo(x(0), h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.16), lineColor.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Cost line, dashed.
    final costPath = Path()..moveTo(x(0), y(data.first.invested));
    for (var i = 1; i < data.length; i++) {
      costPath.lineTo(x(i), y(data[i].invested));
    }
    _dashed(
      canvas,
      costPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = costColor,
    );

    canvas.drawPath(
      valuePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..color = lineColor,
    );

    // Dates under the chart: start, middle, end.
    _label(canvas, fmtDate(data.first.date), 0, h + 8, align: TextAlign.left);
    _label(canvas, fmtDate(data[data.length ~/ 2].date), w / 2, h + 8, align: TextAlign.center);
    _label(canvas, fmtDate(data.last.date), w, h + 8, align: TextAlign.right);

    // Scrubber.
    final s = selected;
    if (s != null) {
      canvas.drawLine(
        Offset(x(s), 0),
        Offset(x(s), h),
        Paint()
          ..color = labelColor
          ..strokeWidth = 1,
      );
      canvas.drawCircle(Offset(x(s), y(data[s].value)), 6, Paint()..color = ringColor);
      canvas.drawCircle(Offset(x(s), y(data[s].value)), 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
