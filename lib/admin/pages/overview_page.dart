import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../admin_app.dart';
import '../admin_store.dart';
import '../admin_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.onNavigate});
  final void Function(int index) onNavigate;

  /// 좌석 수로 가중한 캠퍼스 전체 시간대별 평균 이용률
  static Map<int, double> campusHourly(List<Restaurant> rs) {
    final out = <int, double>{};
    for (var h = 10; h <= 20; h++) {
      var sum = 0.0, seats = 0;
      for (final r in rs) {
        final v = r.hourly[h];
        if (v == null) continue;
        sum += v * r.seats;
        seats += r.seats;
      }
      out[h] = seats == 0 ? 0 : sum / seats;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final st = RestaurantStore.instance;
    final a = AdminStore.instance;
    final now = DateTime.now();
    final rs = st.restaurants;
    final open = rs.where((r) => r.isOpenAt(now)).length;
    final veryBusy = rs.where((r) => r.congestion == Congestion.veryBusy).toList();
    final offline = a.sensors.where((s) => !s.online).toList();
    final lowBattery = a.sensors.where((s) => (s.battery ?? 100) < 20).toList();
    final aiToday = a.weeklyAiRequests.last;
    final aiYesterday = a.weeklyAiRequests[a.weeklyAiRequests.length - 2];
    final aiDiff = aiYesterday == 0 ? 0 : ((aiToday - aiYesterday) / aiYesterday * 100).round();
    final hourly = campusHourly(rs);
    final hours = hourly.keys.toList();
    final fixed = st.fixedRecommendId == null ? null : st.byId(st.fixedRecommendId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: '대시보드',
          description: '캠퍼스 식당 ${rs.length}곳의 실시간 혼잡도와 이용 현황 · ${_hhmm(st.updatedAt)} 기준',
          actions: [
            OutlinedButton.icon(
              onPressed: () => onNavigate(AdminNav.logs),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('로그 보기'),
            ),
            FilledButton.icon(
              onPressed: () => onNavigate(AdminNav.menus),
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: const Text('오늘의 메뉴 관리'),
            ),
          ],
        ),
        ResponsiveGrid(
          minItemWidth: 230,
          children: [
            StatTile(
              label: '현재 이용 인원',
              value: '${st.totalOccupied}',
              unit: '명 / ${st.totalSeats}석',
              icon: Icons.groups_rounded,
              footnote: Text(
                '전체 좌석 ${(st.totalOccupied / st.totalSeats * 100).round()}% 사용 중',
                style: TextStyle(fontSize: 12.5, color: t.textMuted),
              ),
            ),
            StatTile(
              label: '운영 중 식당',
              value: '$open',
              unit: '/ ${rs.length}곳',
              icon: Icons.storefront_outlined,
              iconColor: AdminTokens.good,
              footnote: veryBusy.isEmpty
                  ? const StatusBadge(label: '매우 혼잡 없음', color: AdminTokens.good, icon: Icons.check_circle_rounded)
                  : StatusBadge(label: '매우 혼잡 ${veryBusy.length}곳', color: AdminTokens.critical, icon: Icons.warning_rounded),
            ),
            StatTile(
              label: '오늘 AI 추천',
              value: aiToday.toStringAsFixed(0),
              unit: '회',
              icon: Icons.auto_awesome,
              iconColor: AdminTokens.ai,
              footnote: Text('어제 대비 ${aiDiff >= 0 ? '+' : ''}$aiDiff%', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
            ),
            StatTile(
              label: 'IoT 센서',
              value: '${a.onlineSensors}',
              unit: '/ ${a.sensors.length}',
              icon: Icons.sensors_rounded,
              iconColor: offline.isEmpty ? AdminTokens.good : AdminTokens.critical,
              footnote: offline.isEmpty
                  ? const StatusBadge(label: '모두 연결됨', color: AdminTokens.good, icon: Icons.check_circle_rounded)
                  : StatusBadge(label: '연결 끊김 ${offline.length}개', color: AdminTokens.critical, icon: Icons.cancel_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TwoCol(
          left: Panel(
            title: '식당별 실시간 혼잡도',
            subtitle: '좌석 센서 · 출입 카운터 기준',
            trailing: TextButton(onPressed: () => onNavigate(AdminNav.restaurants), child: const Text('관리')),
            child: Column(
              children: [
                for (final r in rs) _LiveRow(restaurant: r, onTap: () => onNavigate(AdminNav.restaurants)),
                const SizedBox(height: 8),
                const _Legend(),
              ],
            ),
          ),
          right: Panel(
            title: '확인 필요',
            subtitle: '조치가 필요한 항목',
            child: Column(
              children: [
                for (final r in veryBusy)
                  AlertRow(
                    icon: Icons.groups_rounded,
                    color: AdminTokens.critical,
                    title: '${r.name} 매우 혼잡',
                    detail: '좌석 ${(r.ratio * 100).round()}% · 예상 대기 ${r.waitMinutes}분',
                  ),
                for (final s in offline)
                  AlertRow(
                    icon: Icons.wifi_off_rounded,
                    color: AdminTokens.critical,
                    title: s.name,
                    detail: '연결 끊김 · ${timeAgo(s.lastSeen)}',
                    action: TextButton(onPressed: () => a.reconnect(s), child: const Text('재연결')),
                  ),
                for (final s in lowBattery)
                  AlertRow(
                    icon: Icons.battery_alert_rounded,
                    color: AdminTokens.warning,
                    title: s.name,
                    detail: '배터리 ${s.battery}%',
                    action: TextButton(onPressed: () => onNavigate(AdminNav.sensors), child: const Text('보기')),
                  ),
                if (veryBusy.isEmpty && offline.isEmpty && lowBattery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('모든 항목이 정상입니다', style: TextStyle(color: t.textMuted)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TwoCol(
          left: Panel(
            title: '시간대별 평균 이용률',
            subtitle: '캠퍼스 전체 · 좌석 수 가중 평균 (%)',
            child: BarChart(
              values: [for (final h in hours) hourly[h]! * 100],
              labels: [for (final h in hours) '$h시'],
              unit: '%',
              highlightIndex: hours.contains(now.hour) ? hours.indexOf(now.hour) : null,
              highlightLast: false,
              colorOf: (i) => Congestion.fromRatio(hourly[hours[i]]!).color,
            ),
          ),
          right: Panel(
            title: 'AI 추천 현황',
            subtitle: '오늘 추천된 식당',
            trailing: TextButton(onPressed: () => onNavigate(AdminNav.ai), child: const Text('설정')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fixed != null) ...[
                  StatusBadge(label: '개발 모드 · ${fixed.name} 고정', color: AdminTokens.ai, icon: Icons.push_pin_rounded),
                  const SizedBox(height: 12),
                ],
                HorizontalBars(
                  unit: '회',
                  items: [
                    for (final r in rs)
                      (
                        r.name,
                        r.icon as IconData?,
                        fixed == null ? (aiToday * (1 - r.ratio) / 2).roundToDouble() : (r == fixed ? aiToday : 0.0),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TwoCol(
          left: Panel(
            title: '최근 활동',
            trailing: TextButton(onPressed: () => onNavigate(AdminNav.logs), child: const Text('전체 보기')),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                for (final l in a.logs.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 72, child: StatusBadge.log(l.level)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: l.target,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                                ),
                                TextSpan(
                                  text: '  ${l.message}',
                                  style: TextStyle(color: t.textSub),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${l.actor} · ${timeAgo(l.time)}', style: TextStyle(fontSize: 12, color: t.textMuted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          right: Panel(
            title: '오늘 방문자',
            subtitle: '출입 카운터 누적 (명)',
            trailing: TextButton(onPressed: () => onNavigate(AdminNav.stats), child: const Text('통계')),
            child: HorizontalBars(unit: '명', items: [for (final r in rs) (r.name, r.icon as IconData?, a.weeklyVisitors[r.id]!.last)]),
          ),
        ),
      ],
    );
  }
}

String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.restaurant, required this.onTap});
  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final r = restaurant;
    final open = r.isOpenAt(DateTime.now());
    final status = Text(
      '${r.occupied}/${r.seats}석 · ${open ? (r.waitMinutes == 0 ? '대기 없음' : '대기 약 ${r.waitMinutes}분') : '영업 종료'}'
      '${r.sensorOnline ? '' : ' · 센서 끊김(마지막 값)'}',
      style: TextStyle(fontSize: 12, color: r.sensorOnline ? t.textMuted : AdminTokens.critical),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.name,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: t.text),
        ),
        Text(r.place, style: TextStyle(fontSize: 12, color: t.textMuted)),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 520;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: t.hover,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Row(
              children: [
                RestaurantAvatar(restaurant: r, size: 44),
                const SizedBox(width: 14),
                if (!compact) SizedBox(width: 140, child: title),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact) ...[title, const SizedBox(height: 6)],
                      OccupancyBar(ratio: r.ratio, height: 10),
                      const SizedBox(height: 5),
                      status,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CongestionBadge(r.congestion),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in Congestion.values) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.color, width: 2.5),
                ),
              ),
              const SizedBox(width: 5),
              Text(c.label, style: TextStyle(fontSize: 12, color: t.textMuted)),
              const SizedBox(width: 14),
            ],
          ],
        ),
        Text('여유 < 50% ≤ 혼잡 < 80% ≤ 매우 혼잡', style: TextStyle(fontSize: 12, color: t.textMuted)),
      ],
    );
  }
}
