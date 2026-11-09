import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/restaurant.dart';
import '../mobile_theme.dart';
import '../services/location_service.dart';
import '../widgets/campus_map.dart';
import '../widgets/congestion.dart';
import 'home_screen.dart';

/// 지도 탭: 모든 식당을 혼잡도 색 테두리 핀으로 표시
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  LatLng? _me;
  Restaurant? _selected;
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    final loc = await LocationService.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _me = loc.position;
    });
    _map.move(loc.position, 17);
    if (loc.isFallback) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(loc.error!), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = RestaurantStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Stack(children: [
        Positioned.fill(
          child: CampusMap(
            controller: _map,
            restaurants: store.restaurants,
            me: _me,
            highlight: _selected,
            initialZoom: 17,
            onTapRestaurant: (r) {
              setState(() => _selected = r);
              _map.move(r.position, _map.camera.zoom);
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(children: [
                const Text('식당 지도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                const Flexible(flex: 4, child: FittedBox(child: CongestionLegend())),
              ]),
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: (_selected == null ? 0 : 150) + 16,
          child: FloatingActionButton.small(
            heroTag: 'locate',
            tooltip: '내 위치',
            backgroundColor: context.cardColor,
            foregroundColor: MobileColors.me,
            onPressed: _locating ? null : _locate,
            child: _locating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Icon(Icons.my_location_rounded),
          ),
        ),
        if (_selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Stack(children: [
              RestaurantCard(restaurant: _selected!),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: context.subtle),
                  onPressed: () => setState(() => _selected = null),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
