import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../admin_store.dart';
import '../admin_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'overview_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _id = 'all';

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final st = RestaurantStore.instance;
    final a = AdminStore.instance;
    final rs = st.restaurants;
    final labels = last7DayLabels();
    final now = DateTime.now().hour;

    final weekly = _id == 'all' ? List.generate(7, (i) => rs.fold(0.0, (s, r) => s + a.weeklyVisitors[r.id]![i])) : a.weeklyVisitors[_id]!;
    final hourly = _id == 'all' ? OverviewPage.campusHourly(rs) : st.byId(_id).hourly;
    final hours = hourly.keys.toList()..sort();
    final weekTotal = weekly.fold(0.0, (s, v) => s + v);
    final selectedName = _id == 'all' ? '전체 식당' : st.byId(_id).name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: '이용 통계',
          description: '출입 카운터와 좌석 센서로 집계한 방문자 · 혼잡 패턴',
          actions: [
            FilterDropdown<String>(
              label: '식당',
              value: _id,
              items: {'all': '전체 식당', for (final r in rs) r.id: r.name},
              onChanged: (v) => setState(() => _id = v),
            ),
          ],
        ),
        ResponsiveGrid(
          minItemWidth: 230,
          children: [
            StatTile(label: '오늘 방문자', value: weekly.last.toStringAsFixed(0), unit: '명', icon: Icons.login_rounded),
            StatTile(label: '최근 7일 합계', value: weekTotal.toStringAsFixed(0), unit: '명', icon: Icons.calendar_month_outlined),
            StatTile(
              label: '일 평균',
              value: (weekTotal / 7).toStringAsFixed(0),
              unit: '명',
              icon: Icons.show_chart_rounded,
              iconColor: AdminTokens.ai,
            ),
            StatTile(
              label: '가장 붐비는 시간',
              value: '${_peak(hourly)}시',
              icon: Icons.schedule_rounded,
              iconColor: AdminTokens.critical,
              footnote: Text('평균 이용률 ${(hourly[_peak(hourly)]! * 100).round()}%', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TwoCol(
          left: Panel(
            title: '일별 방문자',
            subtitle: '$selectedName · 최근 7일 (명)',
            child: BarChart(values: weekly, labels: labels, unit: '명'),
          ),
          right: Panel(
            title: '시간대별 평균 이용률',
            subtitle: '$selectedName · 막대 색 = 혼잡도 단계',
            child: BarChart(
              values: [for (final h in hours) hourly[h]! * 100],
              labels: [for (final h in hours) '$h'],
              unit: '%',
              highlightLast: false,
              highlightIndex: hours.contains(now) ? hours.indexOf(now) : null,
              colorOf: (i) => Congestion.fromRatio(hourly[hours[i]]!).color,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          title: '식당별 요약',
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: HScroll(
            minWidth: 760,
            child: AdminTable(
              columns: const ['식당', '오늘 방문자', '7일 합계', '일 평균', '피크 시간', '좌석', '현재 혼잡도'],
              flex: const [18, 11, 11, 10, 10, 9, 12],
              onRowTap: (i) => setState(() => _id = rs[i].id),
              rows: [
                for (final r in rs)
                  () {
                    final w = a.weeklyVisitors[r.id]!;
                    final total = w.fold(0.0, (s, v) => s + v);
                    return [
                      Row(
                        children: [
                          RestaurantAvatar(restaurant: r, size: 30),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              r.name,
                              style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                            ),
                          ),
                        ],
                      ),
                      Text('${w.last.round()}명', style: TextStyle(color: t.text, fontSize: 13)),
                      Text('${total.round()}명', style: TextStyle(color: t.text, fontSize: 13)),
                      Text('${(total / 7).round()}명', style: TextStyle(color: t.textSub, fontSize: 13)),
                      Text('${_peak(r.hourly)}시', style: TextStyle(color: t.textSub, fontSize: 13)),
                      Text('${r.seats}석', style: TextStyle(color: t.textSub, fontSize: 13)),
                      CongestionBadge(r.congestion),
                    ];
                  }(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static int _peak(Map<int, double> m) => m.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}
