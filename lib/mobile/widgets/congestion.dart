import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../mobile_theme.dart';

/// 식당 원형 아이콘. 테두리 색 = 혼잡도 (초록 여유 / 노랑 혼잡 / 빨강 매우 혼잡)
class CongestionRing extends StatelessWidget {
  const CongestionRing({super.key, required this.restaurant, this.size = 68, this.ring = 4});
  final Restaurant restaurant;
  final double size;
  final double ring;

  @override
  Widget build(BuildContext context) {
    final c = restaurant.congestion.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size,
      height: size,
      padding: EdgeInsets.all(ring * 0.75),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c, width: ring),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.28), blurRadius: size * 0.18)],
        color: context.cardColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MobileColors.accent.withValues(alpha: context.isDark ? 0.22 : 0.12),
        ),
        child: Icon(restaurant.icon, size: size * 0.42, color: MobileColors.accent),
      ),
    );
  }
}

/// "● 여유" 형태의 작은 혼잡도 배지
class CongestionBadge extends StatelessWidget {
  const CongestionBadge(this.level, {super.key, this.dense = false});
  final Congestion level;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: level.color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: level.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            level.label,
            style: TextStyle(
              fontSize: dense ? 11.5 : 13,
              fontWeight: FontWeight.w700,
              color: context.isDark ? level.color : level.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 혼잡도 범례
class CongestionLegend extends StatelessWidget {
  const CongestionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in Congestion.values) ...[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.color, width: 3),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            c.label,
            style: TextStyle(fontSize: 12, color: context.subtle, fontWeight: FontWeight.w600),
          ),
          if (c != Congestion.values.last) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

/// 좌석 점유율 막대
class OccupancyBar extends StatelessWidget {
  const OccupancyBar({super.key, required this.restaurant, this.height = 8});
  final Restaurant restaurant;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: context.inactiveFill),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              alignment: Alignment.centerLeft,
              widthFactor: restaurant.ratio.clamp(0.02, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: restaurant.congestion.color),
            ),
          ],
        ),
      ),
    );
  }
}
