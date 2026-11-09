import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../admin_store.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  String _level = 'all';

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final st = RestaurantStore.instance;
    final now = DateTime.now();
    final list = st.restaurants.where((r) => _level == 'all' || r.congestion.name == _level).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: '식당 · 혼잡도',
          description: '좌석 사용률 50% 미만 여유 · 80% 미만 혼잡 · 그 이상 매우 혼잡으로 사용자 앱에 표시됩니다',
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                await st.refresh();
                if (context.mounted) toast(context, '센서 값을 새로 불러왔어요');
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('센서 새로고침'),
            ),
          ],
        ),
        ResponsiveGrid(
          minItemWidth: 260,
          children: [for (final r in st.restaurants) _RestaurantCard(restaurant: r, onEdit: () => _editDialog(context, r))],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '전체 목록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text),
            ),
            const SizedBox(width: 6),
            FilterDropdown<String>(
              label: '혼잡도',
              value: _level,
              items: {'all': '모든 혼잡도', for (final c in Congestion.values) c.name: c.label},
              onChanged: (v) => setState(() => _level = v),
            ),
            Text('${list.length}곳 표시', style: TextStyle(color: t.textMuted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Panel(
          padding: EdgeInsets.zero,
          child: HScroll(
            minWidth: 980,
            child: AdminTable(
              columns: const ['식당', '위치', '혼잡도', '좌석 사용', '예상 대기', '운영', '센서', ''],
              flex: const [20, 13, 11, 18, 9, 12, 10, 8],
              emptyText: '조건에 맞는 식당이 없습니다',
              onRowTap: (i) => _editDialog(context, list[i]),
              rows: [
                for (final r in list)
                  [
                    Row(
                      children: [
                        RestaurantAvatar(restaurant: r, size: 34),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r.name,
                                style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                              ),
                              Text(r.category, style: TextStyle(fontSize: 12, color: t.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(r.place, style: TextStyle(color: t.textSub, fontSize: 13)),
                    CongestionBadge(r.congestion),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${r.occupied} / ${r.seats}석 (${(r.ratio * 100).round()}%)', style: TextStyle(fontSize: 13, color: t.text)),
                          const SizedBox(height: 4),
                          OccupancyBar(ratio: r.ratio, height: 6),
                        ],
                      ),
                    ),
                    Text(r.waitMinutes == 0 ? '없음' : '${r.waitMinutes}분', style: TextStyle(color: t.text, fontSize: 13)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.isOpenAt(now) ? '영업 중' : '영업 종료',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: r.isOpenAt(now) ? AdminTokens.good : t.textMuted,
                          ),
                        ),
                        Text(r.openHours, style: TextStyle(fontSize: 12, color: t.textMuted)),
                      ],
                    ),
                    r.sensorOnline
                        ? const StatusBadge(label: '정상', color: AdminTokens.good, icon: Icons.check_circle_rounded)
                        : const StatusBadge(label: '끊김', color: AdminTokens.critical, icon: Icons.cancel_rounded),
                    IconButton(
                      tooltip: '혼잡도 보정',
                      icon: Icon(Icons.tune_rounded, size: 20, color: t.textSub),
                      onPressed: () => _editDialog(context, r),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 좌석 사용 수 수동 보정 (센서 오작동 · 행사 등)
  void _editDialog(BuildContext context, Restaurant r) {
    var value = r.occupied.toDouble();
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final t = AdminTokens.of(context);
          final level = Congestion.fromRatio(value / r.seats);
          return AlertDialog(
            title: Row(
              children: [
                RestaurantAvatar(restaurant: r, size: 36),
                const SizedBox(width: 12),
                Text('${r.name} 혼잡도 보정'),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('센서 오작동이나 행사 등으로 값이 맞지 않을 때 좌석 사용 수를 직접 입력합니다.', style: TextStyle(color: t.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        '${value.round()} / ${r.seats}석',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text),
                      ),
                      const SizedBox(width: 10),
                      CongestionBadge(level),
                    ],
                  ),
                  Slider(
                    value: value,
                    max: r.seats.toDouble(),
                    divisions: r.seats,
                    activeColor: level.color,
                    onChanged: (v) => setState(() => value = v),
                  ),
                  Text('사용률 ${(value / r.seats * 100).round()}%', style: TextStyle(color: t.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              FilledButton(
                onPressed: () {
                  RestaurantStore.instance.setOccupied(r, value.round());
                  AdminStore.instance.log(
                    AdminLog(LogLevel.info, r.name, '좌석 사용 수 수동 보정 → ${value.round()}석 (${level.label})', actor: AdminStore.adminName),
                  );
                  Navigator.pop(context);
                },
                child: const Text('적용'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant, required this.onEdit});
  final Restaurant restaurant;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final r = restaurant;
    final c = r.congestion;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RestaurantAvatar(restaurant: r, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.text),
                    ),
                    Text(r.place, style: TextStyle(fontSize: 12.5, color: t.textMuted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: '혼잡도 보정',
                onPressed: onEdit,
                icon: Icon(Icons.tune_rounded, size: 20, color: t.textSub),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                c.label,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark ? c.color : c.textColor),
              ),
              const Spacer(),
              Text(
                '${(r.ratio * 100).round()}%',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OccupancyBar(ratio: r.ratio, height: 10),
          const SizedBox(height: 8),
          Text(
            '${r.occupied}/${r.seats}석 · 대기 ${r.waitMinutes == 0 ? '없음' : '약 ${r.waitMinutes}분'}',
            style: TextStyle(fontSize: 12.5, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
