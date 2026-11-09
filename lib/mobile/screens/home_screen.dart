import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../mobile_theme.dart';
import '../widgets/congestion.dart';
import 'home_shell.dart';
import 'recommend_screen.dart';
import 'restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenMap});
  final VoidCallback onOpenMap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Sort { basic, relaxed }

class _HomeScreenState extends State<HomeScreen> {
  _Sort _sort = _Sort.basic;

  @override
  Widget build(BuildContext context) {
    final store = RestaurantStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = [...store.restaurants];
        if (_sort == _Sort.relaxed) list.sort((a, b) => a.ratio.compareTo(b.ratio));
        return RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _Header(),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: AiRecommendCard()),
              SectionTitle(
                '실시간 혼잡도',
                trailing: TextButton.icon(
                  onPressed: store.refresh,
                  style: TextButton.styleFrom(foregroundColor: context.subtle),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('${hhmm(store.updatedAt)} 기준', style: const TextStyle(fontSize: 13)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
                    child: Column(children: [
                      Row(children: [
                        for (final r in store.restaurants) Expanded(child: _RingItem(restaurant: r)),
                      ]),
                      const SizedBox(height: 18),
                      const CongestionLegend(),
                    ]),
                  ),
                ),
              ),
              SectionTitle(
                '식당 목록',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  _SortChip(label: '기본순', selected: _sort == _Sort.basic, onTap: () => setState(() => _sort = _Sort.basic)),
                  const SizedBox(width: 6),
                  _SortChip(label: '여유순', selected: _sort == _Sort.relaxed, onTap: () => setState(() => _sort = _Sort.relaxed)),
                  const SizedBox(width: 4),
                ]),
              ),
              for (final r in list)
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: RestaurantCard(restaurant: r)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                child: OutlinedButton.icon(
                  onPressed: widget.onOpenMap,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: context.fg,
                    side: BorderSide(color: context.isDark ? Colors.white24 : Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 20),
                  label: const Text('지도에서 한눈에 보기', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 10) return '좋은 아침이에요';
    if (h < 15) return '점심 맛있게 드세요';
    return '저녁 식사 하셨나요?';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 10, 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.place_rounded, size: 16, color: MobileColors.accent),
                const SizedBox(width: 3),
                Text('캠퍼스 식당', style: TextStyle(fontSize: 14, color: context.subtle, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(_greeting, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            ]),
          ),
          IconButton(
            tooltip: '알림',
            icon: const Icon(Icons.notifications_none_rounded, size: 26),
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('새 알림이 없어요'), behavior: SnackBarBehavior.floating)),
          ),
        ]),
      ),
    );
  }
}

/// 최상단 AI 추천 카드
class AiRecommendCard extends StatelessWidget {
  const AiRecommendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [MobileColors.ai, MobileColors.ai2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: MobileColors.ai.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text('AI 추천', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('지금 어디로 갈까요?', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text('내 위치에서 가장 가깝고 덜 혼잡한\n식당을 AI가 찾아드려요',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 14, height: 1.4)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: MobileColors.ai,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendScreen())),
            icon: const Icon(Icons.my_location_rounded, size: 20),
            label: const Text('내 위치로 추천받기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

class _RingItem extends StatelessWidget {
  const _RingItem({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final c = restaurant.congestion;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => openRestaurant(context, restaurant),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          CongestionRing(restaurant: restaurant),
          const SizedBox(height: 8),
          Text(restaurant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(c.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.isDark ? c.color : c.textColor)),
        ]),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.fg : context.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? context.bgColor : context.subtle)),
        ),
      ),
    );
  }
}

/// 식당 목록 카드 (홈 · MY 즐겨찾기 공용)
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final open = r.isOpenAt(DateTime.now());
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRestaurant(context, r),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CongestionRing(restaurant: r, size: 58, ring: 3.5),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  CongestionBadge(r.congestion, dense: true),
                ]),
                const SizedBox(height: 3),
                Text('${r.category} · ${r.place}', style: TextStyle(fontSize: 12.5, color: context.subtle)),
                const SizedBox(height: 10),
                OccupancyBar(restaurant: r, height: 6),
                const SizedBox(height: 6),
                Row(children: [
                  Text('좌석 ${r.occupied}/${r.seats}', style: TextStyle(fontSize: 12, color: context.subtle, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    open ? (r.waitMinutes == 0 ? '바로 입장' : '대기 약 ${r.waitMinutes}분') : '영업 종료',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: open ? context.fg : context.subtle),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 6),
            Icon(r.favorite ? Icons.favorite_rounded : Icons.chevron_right_rounded,
                color: r.favorite ? const Color(0xFFFF4D67) : context.subtle, size: 22),
          ]),
        ),
      ),
    );
  }
}

void openRestaurant(BuildContext context, Restaurant r) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: r)));
}
