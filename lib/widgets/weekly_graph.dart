import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// "This Week / Weekly Trend" card matching the Stitch Raw Ledger design:
/// 4px black border, 4px brutal shadow, Anton daily average rate,
/// red brutalist trend line, and mon-sun day columns.
class WeeklyGraph extends StatefulWidget {
  const WeeklyGraph({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<WeeklyGraph> createState() => _WeeklyGraphState();
}

class _WeeklyGraphState extends State<WeeklyGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  static const _labels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final totals = store.weeklyTotals;
    final todayIdx = store.todayWeekdayIndex;

    // Calculate weekly average
    final double weekSum = totals.fold(0.0, (sum, val) => sum + val);
    final int activeDays = (todayIdx + 1).clamp(1, 7);
    final double dailyAvg = activeDays > 0 ? (weekSum / activeDays) : 0;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderBlack, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THIS WEEK',
                      style: AppText.labelBold(11, AppColors.textSecondary,
                          spacing: 1.2),
                    ),
                    Text(
                      'TREND',
                      style: AppText.headlineSm(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.trending_up,
                        size: 20, color: AppColors.primaryRed),
                    const SizedBox(width: 4),
                    Text(
                      '₹${store.formatInr(dailyAvg.round())}/DAY',
                      style: AppText.headlineSm(color: AppColors.primaryRed),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Custom Painted Chart
          SizedBox(
            height: 90,
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BrutalChartPainter(
                    totals: totals,
                    budget: store.budget,
                    todayIdx: todayIdx,
                    progress: _animCtrl.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Day Labels row
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderBlack, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < 7; i++)
                  Text(
                    _labels[i],
                    style: AppText.labelBold(
                      11,
                      i == todayIdx
                          ? AppColors.primaryRed
                          : (i < todayIdx
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrutalChartPainter extends CustomPainter {
  final List<double> totals;
  final double budget;
  final int todayIdx;
  final double progress;

  _BrutalChartPainter({
    required this.totals,
    required this.budget,
    required this.todayIdx,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totals.length < 7) return;

    final double maxVal = totals.reduce((a, b) => a > b ? a : b);
    final double ceiling = (maxVal > budget ? maxVal : budget) * 1.15;
    final double dx = size.width / 6;

    // Line paints
    final linePaint = Paint()
      ..color = AppColors.primaryRed
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final dashedPaint = Paint()
      ..color = AppColors.surfaceDim
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pointBlack = Paint()
      ..color = AppColors.borderBlack
      ..style = PaintingStyle.fill;

    final pointRed = Paint()
      ..color = AppColors.primaryRed
      ..style = PaintingStyle.fill;

    final List<Offset> points = [];
    for (int i = 0; i < 7; i++) {
      final double yRatio = ceiling <= 0 ? 0 : (totals[i] / ceiling);
      final double targetY = size.height - (yRatio * size.height * 0.85);
      final double currentY = size.height - ((size.height - targetY) * progress);
      points.add(Offset(i * dx, currentY));
    }

    // Draw past segment
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i <= todayIdx; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw future dashed line
    for (int i = todayIdx; i < 6; i++) {
      canvas.drawLine(points[i], points[i + 1], dashedPaint);
    }

    // Draw vertex points
    for (int i = 0; i < 7; i++) {
      final p = points[i];
      if (i == todayIdx) {
        // Red square on today
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 10, height: 10),
          pointRed,
        );
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 10, height: 10),
          Paint()
            ..color = AppColors.borderBlack
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      } else if (i <= todayIdx) {
        // Black circle on past
        canvas.drawCircle(p, 4, pointBlack);
      } else {
        // Empty circle on future
        canvas.drawCircle(
          p,
          3,
          Paint()
            ..color = AppColors.surfaceDim
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrutalChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.totals != totals;
}
