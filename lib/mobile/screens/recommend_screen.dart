import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../mobile_theme.dart';
import '../services/location_service.dart';
import '../widgets/campus_map.dart';
import '../widgets/congestion.dart';
import 'home_screen.dart';

/// AI 추천 화면: GPS로 현재 위치 → 혼잡도 분석 → 추천 식당과 경로를 지도에 표시
class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  static const _steps = ['현재 위치 확인 중', '식당별 혼잡도 분석 중', '최적의 식당 고르는 중'];
  int _step = 0;
  LocationResult? _loc;
  Restaurant? _pick;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _step = 0;
      _pick = null;
    });
    final loc = await LocationService.current();
    if (!mounted) return;
    setState(() => _step = 1);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _step = 2);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loc = loc;
      _pick = RestaurantStore.instance.recommend(loc.position);
    });
    if (loc.isFallback) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${loc.error} · 캠퍼스 기준으로 추천했어요'), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pick = _pick;
    final loc = _loc;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: pick == null || loc == null
                ? CampusMap(restaurants: RestaurantStore.instance.restaurants, interactive: false, initialZoom: 16.5)
                : CampusMap(
                    key: ValueKey(loc.position),
                    restaurants: RestaurantStore.instance.restaurants,
                    me: loc.position,
                    highlight: pick,
                    routeTo: pick,
                    fitPadding: const EdgeInsets.fromLTRB(70, 140, 70, 380),
                    onTapRestaurant: (r) => openRestaurant(context, r),
                  ),
          ),
          // 상단 바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _CircleBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18, color: MobileColors.ai),
                          SizedBox(width: 8),
                          Text('AI 식당 추천', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CircleBtn(icon: Icons.refresh_rounded, onTap: pick == null ? null : _run),
                ],
              ),
            ),
          ),
          // 하단 결과 / 로딩
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: pick == null || loc == null
                  ? _Analyzing(key: const ValueKey('loading'), step: _step, steps: _steps)
                  : _ResultSheet(key: const ValueKey('result'), restaurant: pick, loc: loc, onRetry: _run),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }
}

class _Analyzing extends StatelessWidget {
  const _Analyzing({super.key, required this.step, required this.steps});
  final int step;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return _SheetBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: MobileColors.ai)),
              SizedBox(width: 12),
              Text('AI가 분석하고 있어요', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    i < step
                        ? Icons.check_circle_rounded
                        : (i == step ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
                    size: 20,
                    color: i <= step ? MobileColors.ai : context.subtle.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                      color: i <= step ? context.fg : context.subtle,
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

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({super.key, required this.restaurant, required this.loc, required this.onRetry});
  final Restaurant restaurant;
  final LocationResult loc;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final m = LocationService.meters(loc.position, r.position);
    final walk = LocationService.walkMinutes(m);
    Widget reason(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MobileColors.ai),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: context.subtle)),
        ],
      ),
    );

    return _SheetBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CongestionRing(restaurant: r, size: 60, ring: 4),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI 추천 식당',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MobileColors.ai),
                    ),
                    const SizedBox(height: 2),
                    Text(r.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    Text('${r.category} · ${r.place}', style: TextStyle(fontSize: 13, color: context.subtle)),
                  ],
                ),
              ),
              CongestionBadge(r.congestion),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: context.inactiveFill, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                stat(LocationService.formatDistance(m), loc.isFallback ? '캠퍼스 기준' : '내 위치에서'),
                stat('도보 $walk분', '예상 이동'),
                stat(r.waitMinutes == 0 ? '없음' : '${r.waitMinutes}분', '예상 대기'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          reason(Icons.event_seat_rounded, '좌석 ${(r.ratio * 100).round()}% 사용 중 · 지금 가장 여유로워요'),
          reason(Icons.near_me_rounded, '가까운 식당 중 혼잡도가 가장 낮아요'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: context.fg,
                    side: BorderSide(color: context.isDark ? Colors.white24 : Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('다른 식당', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => openRestaurant(context, r),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: MobileColors.ai,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                  label: const Text('메뉴 · 정보 보기', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetBox extends StatelessWidget {
  const _SheetBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
