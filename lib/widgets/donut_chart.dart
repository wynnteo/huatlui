import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class DonutSlice {
  final String label;
  final double value;
  final Color color;
  final String detail; // shown in the middle when this slice is tapped
  const DonutSlice({required this.label, required this.value, required this.color, this.detail = ''});
}

/// A thin ring. Tap a slice and the middle tells you what it is; tap again
/// (or tap the middle) to go back to the total.
class DonutChart extends StatefulWidget {
  final List<DonutSlice> slices;
  final String totalText;
  final String totalCaption;
  final double size;
  const DonutChart({super.key, required this.slices, required this.totalText, required this.totalCaption, this.size = 210});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _selected;
  static const double _stroke = 22;

  double get _total => widget.slices.fold<double>(0, (s, e) => s + e.value);

  void _onTap(Offset p) {
    final r = widget.size / 2;
    final dx = p.dx - r;
    final dy = p.dy - r;
    final dist = math.sqrt(dx * dx + dy * dy);
    final ring = r - _stroke / 2;
    if (dist < ring - _stroke || dist > ring + _stroke || _total <= 0) {
      setState(() => _selected = null);
      return;
    }
    var angle = math.atan2(dy, dx) + math.pi / 2; // 0 at 12 o'clock, clockwise
    if (angle < 0) angle += 2 * math.pi;
    var acc = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      acc += widget.slices[i].value / _total * 2 * math.pi;
      if (angle <= acc) {
        setState(() => _selected = _selected == i ? null : i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sel = (_selected != null && _selected! < widget.slices.length) ? widget.slices[_selected!] : null;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTap(d.localPosition),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _DonutPainter(
                  fractions: [for (final s in widget.slices) _total > 0 ? s.value / _total : 0.0],
                  colors: [for (final s in widget.slices) s.color],
                  selected: _selected,
                  stroke: _stroke,
                  track: c.outline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sel?.label ?? widget.totalCaption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textTertiary),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        sel != null ? sel.detail : widget.totalText,
                        style: AppTheme.numeral(context, size: 18, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;
  final int? selected;
  final double stroke;
  final Color track;

  _DonutPainter({required this.fractions, required this.colors, required this.selected, required this.stroke, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    paint
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, paint);

    final gap = fractions.length > 1 ? 0.035 : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * 2 * math.pi;
      final dim = selected != null && selected != i;
      paint
        ..strokeWidth = selected == i ? stroke + 4 : stroke
        ..color = dim ? colors[i].withOpacity(0.35) : colors[i];
      final drawSweep = math.max(0.0, sweep - gap);
      if (drawSweep > 0) canvas.drawArc(rect, start + gap / 2, drawSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.selected != selected || old.fractions != fractions || old.colors != colors || old.track != track;
}
