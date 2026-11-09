import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../admin_theme.dart';

/// 세로 막대 차트 (단일 시리즈). 막대마다 hover 툴팁.
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, required this.labels, required this.unit, this.height = 220, this.highlightLast = true});
  final List<double> values;
  final List<String> labels;
  final String unit;
  final double height;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final maxV = _niceMax(values.reduce(math.max));
    const ticks = 4;
    return SizedBox(
      height: height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Y축 눈금
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = ticks; i >= 0; i--)
                Text(_fmt(maxV * i / ticks), style: TextStyle(fontSize: 11, color: t.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(children: [
            // 그리드 선
            Positioned.fill(
              bottom: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [for (var i = 0; i <= ticks; i++) Container(height: 1, color: i == ticks ? t.border : t.grid)],
              ),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Tooltip(
                    message: '${labels[i]}\n${values[i].toStringAsFixed(1)} $unit',
                    waitDuration: Duration.zero,
                    child: Column(children: [
                      Expanded(
                        child: LayoutBuilder(builder: (context, c) {
                          final h = c.maxHeight * values[i] / maxV;
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              child: Container(
                                height: h,
                                decoration: BoxDecoration(
                                  color: highlightLast && i != values.length - 1 ? t.series1.withValues(alpha: 0.45) : t.series1,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(
                        height: 22,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(labels[i], style: TextStyle(fontSize: 11.5, color: t.textMuted)),
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// 선 차트 (단일 시리즈). 마우스를 올리면 세로 가이드선 + 값 툴팁.
class LineChart extends StatefulWidget {
  const LineChart({super.key, required this.values, required this.xLabel, required this.unit, this.height = 220});
  final List<double> values;
  final String Function(int i) xLabel;
  final String unit;
  final double height;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  int? _hover;

  static const _left = 36.0;
  static const _bottom = 22.0;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final v = widget.values;
    // 눈금 4칸이 정수로 떨어지도록 범위를 4의 배수로 맞춤
    final lo = (v.reduce(math.min) - 1).floorToDouble();
    final hi = lo + (((v.reduce(math.max) + 1) - lo) / 4).ceil() * 4;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, c) {
        final plotW = c.maxWidth - _left;
        double xOf(int i) => _left + plotW * i / (v.length - 1);
        return MouseRegion(
          onHover: (e) {
            final x = e.localPosition.dx - _left;
            final i = (x / plotW * (v.length - 1)).round().clamp(0, v.length - 1);
            if (i != _hover) setState(() => _hover = i);
          },
          onExit: (_) => setState(() => _hover = null),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LinePainter(values: v, lo: lo, hi: hi, tokens: t, hover: _hover, xLabel: widget.xLabel, left: _left, bottom: _bottom),
              ),
            ),
            if (_hover != null)
              Positioned(
                left: (xOf(_hover!) - 60).clamp(0, c.maxWidth - 120),
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.panel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.border),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.xLabel(_hover!), style: TextStyle(fontSize: 11.5, color: t.textMuted)),
                      Text('${v[_hover!].toStringAsFixed(1)} ${widget.unit}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.text)),
                    ]),
                  ),
                ),
              ),
          ]),
        );
      }),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.lo,
    required this.hi,
    required this.tokens,
    required this.hover,
    required this.xLabel,
    required this.left,
    required this.bottom,
  });

  final List<double> values;
  final double lo, hi, left, bottom;
  final AdminTokens tokens;
  final int? hover;
  final String Function(int) xLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final plotH = size.height - bottom;
    final plotW = size.width - left;
    Offset pt(int i) => Offset(left + plotW * i / (values.length - 1), plotH * (1 - (values[i] - lo) / (hi - lo)));

    // 그리드 + Y 눈금
    const ticks = 4;
    final grid = Paint()
      ..color = tokens.grid
      ..strokeWidth = 1;
    for (var i = 0; i <= ticks; i++) {
      final y = plotH * i / ticks;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), i == ticks ? (Paint()..color = tokens.border) : grid);
      _text(canvas, (hi - (hi - lo) * i / ticks).toStringAsFixed(0), Offset(0, y - 7), tokens.textMuted, width: left - 8, align: TextAlign.right);
    }
    // X 라벨 (6칸마다)
    for (var i = 0; i < values.length; i += 6) {
      _text(canvas, xLabel(i), Offset(pt(i).dx - 20, plotH + 6), tokens.textMuted, width: 40, align: TextAlign.center);
    }

    // 영역 + 선
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p0 = pt(i - 1), p1 = pt(i);
      final mx = (p0.dx + p1.dx) / 2;
      path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }
    final area = Path.from(path)
      ..lineTo(pt(values.length - 1).dx, plotH)
      ..lineTo(left, plotH)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.series1.withValues(alpha: 0.18), tokens.series1.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, plotH)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = tokens.series1
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    if (hover != null) {
      final p = pt(hover!);
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, plotH), Paint()..color = tokens.textMuted.withValues(alpha: 0.5));
      canvas.drawCircle(p, 6, Paint()..color = tokens.panel);
      canvas.drawCircle(p, 4.5, Paint()..color = tokens.series1);
    }
  }

  void _text(Canvas c, String s, Offset o, Color color, {required double width, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 11, color: color)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values || old.hover != hover || old.tokens != tokens;
}

/// 가로 막대 순위 목록 (항목 이름 + 막대 + 값). 막대 hover 시 툴팁.
class HorizontalBars extends StatelessWidget {
  const HorizontalBars({super.key, required this.items, this.unit = ''});
  final List<(String label, IconData? icon, double value)> items;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final maxV = items.isEmpty ? 1.0 : items.map((e) => e.$3).reduce(math.max);
    return Column(children: [
      for (final (label, icon, value) in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Tooltip(
            message: '$label: ${_fmt(value)}$unit',
            waitDuration: Duration.zero,
            child: Row(children: [
              if (icon != null) ...[Icon(icon, size: 16, color: t.textMuted), const SizedBox(width: 8)],
              SizedBox(width: 96, child: Text(label, style: TextStyle(fontSize: 13, color: t.textSub), overflow: TextOverflow.ellipsis)),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: math.max(4, c.maxWidth * value / maxV),
                      height: 12,
                      decoration: BoxDecoration(color: t.series1, borderRadius: const BorderRadius.horizontal(right: Radius.circular(4))),
                    ),
                  );
                }),
              ),
              SizedBox(
                width: 52,
                child: Text('${_fmt(value)}$unit', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text)),
              ),
            ]),
          ),
        ),
    ]);
  }
}

double _niceMax(double v) {
  if (v <= 0) return 1;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final m in [1, 2, 2.5, 5, 10]) {
    if (m * mag >= v) return m * mag;
  }
  return 10 * mag;
}

String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
