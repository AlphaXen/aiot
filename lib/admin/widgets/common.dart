import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../admin_store.dart';
import '../admin_theme.dart';

/// 흰 패널 카드
class Panel extends StatelessWidget {
  const Panel({super.key, this.title, this.subtitle, this.trailing, required this.child, this.padding = const EdgeInsets.all(20)});
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: t.text),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: TextStyle(fontSize: 12.5, color: t.textMuted)),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// 페이지 상단 제목 + 우측 액션
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.description, this.actions = const []});
  final String title;
  final String? description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        runSpacing: 12,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.3),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(description!, style: TextStyle(color: t.textMuted, fontSize: 13.5)),
              ],
            ],
          ),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

/// KPI 숫자 타일
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.unit, this.icon, this.iconColor, this.footnote});
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? iconColor;
  final Widget? footnote;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: t.textSub, fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ),
              if (icon != null)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AdminTokens.accent).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: iconColor ?? AdminTokens.accent),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.5),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(fontSize: 14, color: t.textMuted, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          if (footnote != null) ...[const SizedBox(height: 6), footnote!],
        ],
      ),
    );
  }
}

/// 온라인/오프라인 등 상태 배지 (색 + 아이콘 + 글자)
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  factory StatusBadge.online(bool online) => online
      ? const StatusBadge(label: '온라인', color: AdminTokens.good, icon: Icons.check_circle_rounded)
      : const StatusBadge(label: '오프라인', color: AdminTokens.critical, icon: Icons.cancel_rounded);

  factory StatusBadge.log(LogLevel l) => switch (l) {
    LogLevel.info => const StatusBadge(label: '정보', color: AdminTokens.accent, icon: Icons.info_rounded),
    LogLevel.warning => const StatusBadge(label: '경고', color: AdminTokens.warning, icon: Icons.warning_rounded),
    LogLevel.error => const StatusBadge(label: '오류', color: AdminTokens.critical, icon: Icons.error_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// 식당 원형 아이콘 (테두리 색 = 혼잡도, 사용자 앱과 동일한 규칙)
class RestaurantAvatar extends StatelessWidget {
  const RestaurantAvatar({super.key, required this.restaurant, this.size = 38});
  final Restaurant restaurant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.panel,
        border: Border.all(color: restaurant.congestion.color, width: size * 0.08),
      ),
      child: Icon(restaurant.icon, color: AdminTokens.accent, size: size * 0.5),
    );
  }
}

/// 혼잡도 배지 (● 여유 / 혼잡 / 매우 혼잡)
class CongestionBadge extends StatelessWidget {
  const CongestionBadge(this.level, {super.key});
  final Congestion level;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: level.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark ? level.color : level.textColor),
          ),
        ],
      ),
    );
  }
}

/// 좌석 점유율 막대 (혼잡도 색)
class OccupancyBar extends StatelessWidget {
  const OccupancyBar({super.key, required this.ratio, this.height = 8});
  final double ratio;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: t.grid),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.02, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: Congestion.fromRatio(ratio).color),
            ),
          ],
        ),
      ),
    );
  }
}

/// 간단한 데이터 테이블 (헤더 + 행, 행 hover 강조)
class AdminTable extends StatelessWidget {
  const AdminTable({super.key, required this.columns, required this.rows, this.flex, this.onRowTap, this.emptyText = '데이터가 없습니다'});
  final List<String> columns;
  final List<List<Widget>> rows;
  final List<int>? flex;
  final void Function(int index)? onRowTap;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final f = flex ?? List.filled(columns.length, 1);
    Widget row(List<Widget> cells) => Row(
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: f[i],
            child: Align(alignment: Alignment.centerLeft, child: cells[i]),
          ),
      ],
    );
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: row([
            for (final c in columns)
              Text(
                c,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.textMuted),
              ),
          ]),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text(emptyText, style: TextStyle(color: t.textMuted)),
          ),
        for (var i = 0; i < rows.length; i++)
          Material(
            color: Colors.transparent,
            child: InkWell(
              hoverColor: t.hover,
              onTap: onRowTap == null ? null : () => onRowTap!(i),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: i == rows.length - 1 ? Colors.transparent : t.border)),
                ),
                child: row(rows[i]),
              ),
            ),
          ),
      ],
    );
  }
}

/// 상단 필터용 드롭다운
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({super.key, required this.value, required this.items, required this.onChanged, required this.label});
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: t.panel,
          hint: Text(label),
          style: TextStyle(color: t.text, fontSize: 13.5),
          items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// 화면 너비에 따라 열 개수가 바뀌는 그리드
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minItemWidth = 240, this.spacing = 16});
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / minItemWidth).floor().clamp(1, children.length);
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      },
    );
  }
}

/// 넓은 화면에서는 3:2 두 칸, 좁으면 세로로 쌓기
class TwoCol extends StatelessWidget {
  const TwoCol({super.key, required this.left, required this.right, this.leftFlex = 3, this.rightFlex = 2});
  final Widget left, right;
  final int leftFlex, rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            const SizedBox(width: 16),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

/// 표가 화면보다 넓으면 가로 스크롤
class HScroll extends StatelessWidget {
  const HScroll({super.key, required this.minWidth, required this.child});
  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= minWidth) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: child),
        );
      },
    );
  }
}

/// 아이콘 + 제목 + 설명 + (액션) 한 줄
class AlertRow extends StatelessWidget {
  const AlertRow({super.key, required this.icon, required this.color, required this.title, required this.detail, this.action});
  final IconData icon;
  final Color color;
  final String title, detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: t.text),
                ),
                Text(detail, style: TextStyle(fontSize: 12.5, color: t.textMuted)),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// 사용자에게 짧은 결과 알림
void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, width: 420));
}
