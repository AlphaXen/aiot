import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/restaurant.dart';

class LocationResult {
  const LocationResult(this.position, {this.error});
  final LatLng position;

  /// null 이면 실제 GPS 위치, 값이 있으면 실패 사유(위치는 캠퍼스 기본값)
  final String? error;
  bool get isFallback => error != null;
}

/// GPS 현재 위치 조회. 실패하면 캠퍼스 중심 좌표로 대체합니다.
class LocationService {
  static const _distance = Distance();

  static Future<LocationResult> current() async {
    LocationResult fallback(String msg) => LocationResult(RestaurantStore.campusCenter, error: msg);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallback('위치 서비스가 꺼져 있어요');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return fallback('위치 권한이 거부되었어요');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      return LocationResult(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      return fallback('현재 위치를 가져오지 못했어요');
    }
  }

  static double meters(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

  /// 도보 4km/h 기준
  static int walkMinutes(double meters) => (meters / 67).ceil().clamp(1, 999);

  static String formatDistance(double m) => m < 1000 ? '${m.round()}m' : '${(m / 1000).toStringAsFixed(1)}km';
}
