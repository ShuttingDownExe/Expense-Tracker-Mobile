import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// "This Week" card: a line chart where the y-axis runs from the daily budget
/// (top) down to ₹0 (bottom). Past days draw a solid gold line (animated),
/// today shows a pulsing dot, and future days are a dashed grey segment with
/// hollow dots — exactly as specified in the design.
class WeeklyGraph extends StatefulWidget {
  const WeeklyGraph({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<WeeklyGraph> createState() => _WeeklyGraphState();
}

class _WeeklyGraphState extends State<WeeklyGraph>
    with TickerProviderStateMixin {
  late final AnimationController _lineCtrl; // one-shot line draw
  late final AnimationController _pulseCtrl; // infinite today pulse

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _lineCtrl.forward();
    });
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Sunday-first, matching the API's /analytics/weekly day indexing.
  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final todayIdx = store.todayWeekdayIndex;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('THIS WEEK', style: AppText.cardHeading),
              Text(_monthLabel(),
                  style: AppText.label(11, AppColors.textFaint)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: Listenable.merge([_lineCtrl, _pulseCtrl]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _GraphPainter(
                    totals: store.weeklyTotals,
                    budget: store.budget,
                    todayIndex: todayIdx,
                    lineProgress: _lineCtrl.value,
                    pulse: _pulseCtrl.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Text(
                  _labels[i],
                  style: AppText.label(
                    i == todayIdx ? 12 : 11,
                    i == todayIdx
                        ? AppColors.gold
                        : i < todayIdx
                            ? const Color(0xFF666666)
                            : AppColors.textDark,
                    weight: i == todayIdx ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' //
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.totals,
    required this.budget,
    required this.todayIndex,
    required this.lineProgress,
    required this.pulse,
  });

  final List<double> totals;
  final double budget;
  final int todayIndex;
  final double lineProgress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 6.0;
    const botPad = 6.0;
    final usableH = size.height - topPad - botPad;
    final stepX = size.width / 6; // 7 points → 6 gaps

    Offset pointFor(int i) {
      final v = budget <= 0 ? 0.0 : (totals[i] / budget).clamp(0.0, 1.0);
      // value==budget → top, value==0 → bottom
      final y = topPad + (1 - v) * usableH;
      return Offset(i * stepX, y);
    }

    final points = List.generate(7, pointFor);
    final gold = const Color(0xFFC9A84C);

    // Budget reference line (dashed gold near the top).
    _drawDashedLine(
      canvas,
      Offset(0, topPad),
      Offset(size.width, topPad),
      Paint()
        ..color = gold.withValues(alpha: 0.3)
        ..strokeWidth = 0.6,
      dash: 4,
      gap: 4,
    );

    final clampToday = todayIndex.clamp(0, 6);

    // Gradient fill under the past (gold) segment.
    if (clampToday > 0) {
      final fillPath = Path()..moveTo(points[0].dx, size.height - botPad);
      for (var i = 0; i <= clampToday; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points[clampToday].dx, size.height - botPad);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gold.withValues(alpha: 0.28), gold.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // Future dashed grey segment + hollow dots.
    final futurePaint = Paint()
      ..color = AppColors.textDark
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = clampToday; i < 6; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1], futurePaint,
          dash: 5, gap: 5);
    }
    for (var i = clampToday + 1; i < 7; i++) {
      canvas.drawCircle(points[i], 3, futurePaint);
    }

    // Past gold line, drawn progressively (stroke-dashoffset equivalent).
    final goldLine = Paint()
      ..color = gold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pastPath = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i <= clampToday; i++) {
      pastPath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(_trimPath(pastPath, lineProgress), goldLine);

    // Past day dots (hollow gold), then today's pulsing dot.
    final dotFill = Paint()..color = AppColors.bgSurface;
    final dotStroke = Paint()
      ..color = gold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < clampToday; i++) {
      canvas.drawCircle(points[i], 4, dotFill);
      canvas.drawCircle(points[i], 4, dotStroke);
    }

    // Today: expanding pulse ring + solid gold dot.
    final t = points[clampToday];
    final ringR = 5 + pulse * 9; // scale 1 → ~2.4
    canvas.drawCircle(
      t,
      ringR,
      Paint()..color = gold.withValues(alpha: (1 - pulse) * 0.7),
    );
    canvas.drawCircle(t, 5, Paint()..color = gold);
  }

  /// Returns the first [progress] fraction of [path] (by length).
  Path _trimPath(Path path, double progress) {
    if (progress >= 1) return path;
    final metrics = path.computeMetrics().toList();
    final out = Path();
    var total = 0.0;
    for (final m in metrics) {
      total += m.length;
    }
    var target = total * progress;
    for (final m in metrics) {
      if (target <= 0) break;
      final len = m.length < target ? m.length : target;
      out.addPath(m.extractPath(0, len), Offset.zero);
      target -= len;
    }
    return out;
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {required double dash, required double gap}) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var dist = 0.0;
    while (dist < total) {
      final start = a + dir * dist;
      final end = a + dir * (dist + dash).clamp(0, total);
      canvas.drawLine(start, end, paint);
      dist += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.lineProgress != lineProgress ||
      old.pulse != pulse ||
      old.totals != totals;
}
