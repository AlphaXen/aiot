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
  final ValueChanged<Restaurant>? onTapRestaurant;

  @override
  Widget build(BuildContext context) {
    final fitPoints = [
      if (me != null && routeTo != null) ...[me!, routeTo!.position],
    ];
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter ?? RestaurantStore.campusCenter,
        initialZoom: initialZoom,
        initialCameraFit: fitPoints.length == 2 ? CameraFit.coordinates(coordinates: fitPoints, padding: fitPadding, maxZoom: 18) : null,
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
            for (final r in restaurants)
              Marker(
                point: r.position,
                width: r == highlight ? 120 : 96,
                height: _pinHeight(r == highlight),
                // 원형 아이콘의 중심이 실제 좌표에 오도록 (이름표는 그 아래)
                alignment: Alignment(0, (_pinHeight(r == highlight) - _circle(r == highlight)) / _pinHeight(r == highlight)),
                child: _RestaurantPin(
                  restaurant: r,
                  big: r == highlight,
                  onTap: onTapRestaurant == null ? null : () => onTapRestaurant!(r),
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
