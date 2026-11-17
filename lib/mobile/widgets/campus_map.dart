import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/restaurant.dart';
import '../mobile_theme.dart';

/// OpenStreetMap 기반 캠퍼스 지도 (API 키 불필요)
class CampusMap extends StatelessWidget {
  const CampusMap({
    super.key,
    required this.restaurants,
    this.controller,
    this.me,
    this.highlight,
    this.routeTo,
    this.initialCenter,
    this.initialZoom = 17,
    this.fitPadding = const EdgeInsets.all(60),
    this.interactive = true,
    this.fitAll = false,
    this.onTapRestaurant,
  });

  final List<Restaurant> restaurants;
  final MapController? controller;
  final LatLng? me;
  final Restaurant? highlight;

  /// 내 위치에서 이 식당까지 점선 경로 표시
  final Restaurant? routeTo;
  final LatLng? initialCenter;
  final double initialZoom;
  final EdgeInsets fitPadding;
  final bool interactive;

  /// 처음 열 때 모든 식당이 보이도록 맞춤 (경로 표시가 있으면 경로 우선)
  final bool fitAll;
  final ValueChanged<Restaurant>? onTapRestaurant;

  @override
  Widget build(BuildContext context) {
    final groups = RestaurantStore.groupByPosition(restaurants);
    final fitPoints = [
      if (me != null && routeTo != null)
        ...[me!, routeTo!.position]
      else if (fitAll && groups.length >= 2)
        for (final g in groups) g.first.position,
    ];
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter ?? RestaurantStore.campusCenter,
        initialZoom: initialZoom,
        initialCameraFit: fitPoints.length >= 2 ? CameraFit.coordinates(coordinates: fitPoints, padding: fitPadding, maxZoom: 18) : null,
        interactionOptions: InteractionOptions(flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
      ),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.aiot'),
        if (me != null && routeTo != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [me!, routeTo!.position],
                color: MobileColors.ai,
                strokeWidth: 5,
                pattern: StrokePattern.dotted(spacingFactor: 1.6),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final g in groups)
              if (g.length == 1)
                Marker(
                  point: g.first.position,
                  width: g.first == highlight ? 120 : 96,
                  height: _pinHeight(g.first == highlight),
                  // 원형 아이콘의 중심이 실제 좌표에 오도록 (이름표는 그 아래)
                  alignment: _pinAlignment(g.first == highlight),
                  child: _RestaurantPin(
                    restaurant: g.first,
                    big: g.first == highlight,
                    onTap: onTapRestaurant == null ? null : () => onTapRestaurant!(g.first),
                  ),
                )
              else
                // 같은 건물(좌표 동일, 층만 다름): 핀 하나에 겹친 원으로 표시하고, 누르면 식당 선택
                Marker(
                  point: g.first.position,
                  width: g.contains(highlight) ? 150 : 128,
                  height: _pinHeight(g.contains(highlight)),
                  alignment: _pinAlignment(g.contains(highlight)),
                  child: _GroupPin(
                    restaurants: g,
                    highlight: g.contains(highlight) ? highlight : null,
                    onTap: onTapRestaurant == null
                        ? null
                        : () async {
                            final picked = await pickRestaurantInGroup(context, g);
                            if (picked != null) onTapRestaurant!(picked);
                          },
                  ),
                ),
            if (me != null) Marker(point: me!, width: 30, height: 30, child: const _MeDot()),
          ],
        ),
        // ⓘ 버튼으로 접히는 출처 표기 (좁은 화면에서도 넘치지 않음, 오른쪽 아래 버튼과 겹치지 않게 왼쪽)
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

double _circle(bool big) => big ? 54 : 40;
double _pinHeight(bool big) => big ? 92 : 74;
Alignment _pinAlignment(bool big) => Alignment(0, (_pinHeight(big) - _circle(big)) / _pinHeight(big));

/// 같은 건물에 있는 식당 중 하나 고르기
Future<Restaurant?> pickRestaurantInGroup(BuildContext context, List<Restaurant> group) {
  return showModalBottomSheet<Restaurant>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Text(
                '이 건물의 식당 ${group.length}곳',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final r in group)
              ListTile(
                onTap: () => Navigator.of(context).pop(r),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: r.congestion.color, width: 3),
                  ),
                  child: Icon(r.icon, size: 20, color: MobileColors.accent),
                ),
                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${r.place} · ${r.category}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  r.congestion.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark ? r.congestion.color : r.congestion.textColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// 같은 좌표의 식당들: 겹친 원 + 개수 배지 + 이름표 하나.
/// 원 묶음 전체가 가운데 정렬되어 묶음의 가운데가 실제 좌표에 옵니다.
class _GroupPin extends StatelessWidget {
  const _GroupPin({required this.restaurants, this.highlight, this.onTap});
  final List<Restaurant> restaurants;
  final Restaurant? highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final big = highlight != null;
    final size = _circle(big);
    final step = size * 0.58;
    // 선택된 식당은 맨 앞(오른쪽)에
    final order = [...restaurants.where((r) => r != highlight), ?highlight];
    final label = highlight?.name ?? restaurants.map((r) => r.name).join(' · ');
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size + step * (order.length - 1),
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final (i, r) in order.indexed)
                  Positioned(
                    left: step * i,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: r.congestion.color, width: r == highlight ? 5 : 4),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Icon(r.icon, size: size * 0.46, color: MobileColors.accent),
                    ),
                  ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: MobileColors.ai,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '${restaurants.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: big ? MobileColors.ai : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: big ? 12.5 : 11, fontWeight: FontWeight.w700, color: big ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantPin extends StatelessWidget {
  const _RestaurantPin({required this.restaurant, required this.big, this.onTap});
  final Restaurant restaurant;
  final bool big;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = restaurant.congestion.color;
    final size = _circle(big);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: c, width: big ? 5 : 4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Icon(restaurant.icon, size: size * 0.48, color: MobileColors.accent),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: big ? MobileColors.ai : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Text(
              restaurant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: big ? 12.5 : 11, fontWeight: FontWeight.w700, color: big ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeDot extends StatefulWidget {
  const _MeDot();

  @override
  State<_MeDot> createState() => _MeDotState();
}

class _MeDotState extends State<_MeDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 14 + 16 * _c.value,
            height: 14 + 16 * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MobileColors.me.withValues(alpha: 0.35 * (1 - _c.value)),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MobileColors.me,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
