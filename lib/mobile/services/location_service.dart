import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/restaurant.dart';

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

  /// 현재 위치를 가져옵니다. 권한이 아직 없으면 이때 브라우저/OS 권한 요청 창이 뜹니다.
  /// (웹은 HTTPS 또는 localhost 에서만 위치를 쓸 수 있습니다)
  static Future<LocationResult> current() async {
    LocationResult fallback(String msg) => LocationResult(RestaurantStore.campusCenter, error: msg);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return fallback('기기 위치 서비스가 꺼져 있거나 이 브라우저에서 위치를 쓸 수 없어요');
      }
      var perm = await Geolocator.checkPermission();
      // 웹에서는 '아직 묻지 않음'도 denied 로 오므로, 이때 권한 요청 창을 띄웁니다.
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return fallback(_deniedForeverMsg);
      if (perm == LocationPermission.denied) return fallback('위치 권한이 거부되었어요');

      final pos = await _position(LocationAccuracy.high, 12).catchError(
        // 실내 등에서 GPS 정밀 위치가 늦으면 네트워크 기반 위치로 한 번 더 시도
        (_) => _position(LocationAccuracy.medium, 8),
        test: (e) => e is TimeoutException,
      );
      return LocationResult(LatLng(pos.latitude, pos.longitude));
    } on PermissionDeniedException {
      return fallback(_deniedForeverMsg);
    } on LocationServiceDisabledException {
      return fallback('기기 위치 서비스가 꺼져 있어요');
    } on TimeoutException {
      return fallback('위치 확인 시간이 초과됐어요');
    } catch (_) {
      return fallback('현재 위치를 가져오지 못했어요');
    }
  }

  static const _deniedForeverMsg = '위치 권한이 허용되지 않았어요. 주소창의 사이트 설정에서 위치를 허용해 주세요';

  /// timeLimit 대신 Dart 쪽에서 직접 시간 제한을 겁니다.
  /// (geolocator_web 4.1.4 는 timeLimit 을 마이크로초로 넘기는 버그가 있어 12초가 약 3시간이 됨)
  static Future<Position> _position(LocationAccuracy accuracy, int seconds) =>
      Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: accuracy)).timeout(Duration(seconds: seconds));

  static double meters(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

  /// 도보 4km/h 기준
  static int walkMinutes(double meters) => (meters / 67).ceil().clamp(1, 999);

  static String formatDistance(double m) => m < 1000 ? '${m.round()}m' : '${(m / 1000).toStringAsFixed(1)}km';
}
