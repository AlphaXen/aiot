import 'package:flutter/material.dart';

import '../data/restaurant.dart';
import '../mobile_theme.dart';
import '../widgets/campus_map.dart';
import '../widgets/congestion.dart';

/// 식당 상세 (플레이스형 상세 페이지: 혼잡도 · 시간대별 혼잡 · 메뉴 · 운영정보 · 위치)
class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final store = RestaurantStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final r = restaurant;
        final c = r.congestion;
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: store.refresh,
            edgeOffset: 120,
            child: CustomScrollView(slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 230,
                backgroundColor: context.bgColor,
                title: Text(r.name),
                actions: [
                  IconButton(
                    tooltip: '즐겨찾기',
                    onPressed: () => store.toggleFavorite(r),
                    icon: Icon(r.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: r.favorite ? const Color(0xFFFF4D67) : null),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.color.withValues(alpha: 0.28), context.bgColor],
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 18),
                    child: CongestionRing(restaurant: r, size: 112, ring: 6),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(children: [
                    Text(r.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('${r.category} · ${r.place}', style: TextStyle(color: context.subtle, fontSize: 14)),
                    const SizedBox(height: 10),
                    _OpenChip(restaurant: r),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                sliver: SliverList.list(children: [
                  _NowCard(restaurant: r, updatedAt: store.updatedAt),
                  const SizedBox(height: 12),
                  _HourlyCard(restaurant: r),
                  const SizedBox(height: 12),
                  _MenuCard(restaurant: r),
                  const SizedBox(height: 12),
                  _InfoCard(restaurant: r),
                  const SizedBox(height: 12),
                  _LocationCard(restaurant: r),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _OpenChip extends StatelessWidget {
  const _OpenChip({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final open = restaurant.isOpenAt(DateTime.now());
    final color = open ? const Color(0xFF16A34A) : context.subtle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(open ? '영업 중' : '영업 종료', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        Text('  ·  ${restaurant.openHours}', style: TextStyle(color: context.subtle, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            const Spacer(),
            ?trailing,
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.restaurant, required this.updatedAt});
  final Restaurant restaurant;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final c = r.congestion;
    final empty = r.seats - r.occupied;
    Widget stat(String v, String l) => Expanded(
          child: Column(children: [
            Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(l, style: TextStyle(fontSize: 12, color: context.subtle)),
          ]),
        );
    return _CardBox(
      title: '실시간 혼잡도',
      trailing: Text('${hhmm(updatedAt)} 기준', style: TextStyle(fontSize: 12.5, color: context.subtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(c.label,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: context.isDark ? c.color : c.textColor, letterSpacing: -0.5)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text('좌석 ${(r.ratio * 100).round()}% 사용 중', style: TextStyle(color: context.subtle, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        OccupancyBar(restaurant: r, height: 12),
        const SizedBox(height: 16),
        Row(children: [
          stat('$empty석', '빈 좌석'),
          stat('${r.seats}석', '전체 좌석'),
          stat(r.waitMinutes == 0 ? '없음' : '약 ${r.waitMinutes}분', '예상 대기'),
        ]),
      ]),
    );
  }
}

/// 시간대별 평균 혼잡도 막대그래프 (현재 시각 강조)
class _HourlyCard extends StatelessWidget {
  const _HourlyCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().hour;
    final hours = restaurant.hourly.keys.toList()..sort();
    final peak = hours.reduce((a, b) => restaurant.hourly[a]! >= restaurant.hourly[b]! ? a : b);
    return _CardBox(
      title: '시간대별 혼잡도',
      trailing: Text('평균 기준', style: TextStyle(fontSize: 12.5, color: context.subtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final h in hours)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (h == now)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('지금', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: MobileColors.accent)),
                      ),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: restaurant.hourly[h]!.clamp(0.06, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: h == now
                                ? Congestion.fromRatio(restaurant.hourly[h]!).color
                                : Congestion.fromRatio(restaurant.hourly[h]!).color.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('$h', style: TextStyle(fontSize: 11, color: h == now ? context.fg : context.subtle, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.inactiveFill, borderRadius: BorderRadius.circular(14)),
          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 13.5), children: [
            const TextSpan(text: '💡 '),
            TextSpan(text: '$peak시', style: const TextStyle(fontWeight: FontWeight.w800)),
            const TextSpan(text: '에 가장 붐벼요. 조금 일찍 또는 늦게 방문해 보세요.'),
          ])),
        ),
      ]),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return _CardBox(
      title: '오늘의 메뉴',
      child: Column(children: [
        for (final m in restaurant.menus)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: MobileColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(restaurant.icon, color: MobileColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(children: [
                  Flexible(child: Text(m.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  if (m.tag != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: MobileColors.accent, borderRadius: BorderRadius.circular(6)),
                      child: Text(m.tag!, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
              ),
              Text(won(m.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
          ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Icon(icon, size: 20, color: context.subtle),
            const SizedBox(width: 12),
            SizedBox(width: 64, child: Text(label, style: TextStyle(color: context.subtle, fontSize: 14))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
        );
    return _CardBox(
      title: '운영 정보',
      child: Column(children: [
        row(Icons.schedule_rounded, '운영시간', r.openHours),
        row(Icons.place_outlined, '위치', r.place),
        row(Icons.event_seat_outlined, '좌석', '${r.seats}석'),
        row(Icons.credit_card_rounded, '결제', r.payments.join(' · ')),
      ]),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return _CardBox(
      title: '위치',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: CampusMap(
            restaurants: [restaurant],
            highlight: restaurant,
            initialCenter: restaurant.position,
            initialZoom: 17.5,
            interactive: false,
          ),
        ),
      ),
    );
  }
}
