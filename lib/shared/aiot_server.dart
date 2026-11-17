import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'restaurant.dart';

/// 센서룸 시뮬레이터(D:\html\aiot)와 같은 Railway 서버.
/// 로컬 서버로 테스트: flutter run --dart-define=AIOT_API=http://localhost:3000
const kAiotApi = String.fromEnvironment('AIOT_API', defaultValue: 'https://aiotserver-production.up.railway.app');

/// 서버의 식당(room) 하나. 시뮬레이터에서 '귀신 출몰'을 누르면 [camera]가 채워집니다.
class SpyRoom {
  SpyRoom(this.id, this.name, this.restaurantId);

  /// 서버 room_id (server/src/rooms.js)
  final String id;
  final String name;

  /// 앱의 Restaurant.id (뉴욕버거만 다름: burger ↔ nyburger)
  final String restaurantId;

  /// {table, dx, freq, x} 또는 null
  Map<String, dynamic>? camera;
  DateTime? updatedAt;

  bool get planted => camera != null;
  double? get freqMhz => (camera?['freq'] as num?)?.toDouble();
}

enum SpyConn { connecting, online, error }

enum RemoveResult { caught, alreadyGone, failed }

/// 센서룸 서버(/api/state)를 3초마다 읽어 두 기능에 반영합니다.
/// - 식당 혼잡도 · 위치: 테스터에서 ＋/− 한 인원(count), 수용 인원(cap), 좌표(lat · lng) → [RestaurantStore.applyLive]
/// - 몰카 탐지: 설치된 몰카(camera). 앱에서 찾은 몰카는 '수거'로 보고하고,
///   서버가 SSE로 camera_removed 를 뿌리면 시뮬레이터 화면에서 귀신이 잡히는 애니메이션이 재생됩니다.
class AiotServer extends ChangeNotifier {
  AiotServer._();
  static final instance = AiotServer._();

  final rooms = [
    SpyRoom('student', '학생식당', 'student'),
    SpyRoom('orange', '오렌지식당', 'orange'),
    SpyRoom('faculty', '교수식당', 'faculty'),
    SpyRoom('burger', '뉴욕버거', 'nyburger'),
  ];

  SpyConn conn = SpyConn.connecting;
  DateTime? syncedAt;
  final clientId = 'app-${Random().nextInt(0x7fffffff).toRadixString(16)}';

  final _http = http.Client();
  Timer? _timer;
  bool _fetching = false;

  List<SpyRoom> get planted => rooms.where((r) => r.planted).toList();

  SpyRoom? byId(String id) {
    for (final r in rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  void start() {
    if (_timer != null) return;
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final res = await _http.get(Uri.parse('$kAiotApi/api/state')).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      for (final s in (j['rooms'] as List).cast<Map<String, dynamic>>()) {
        _apply(s);
      }
      conn = SpyConn.online;
      syncedAt = DateTime.now();
      RestaurantStore.instance.markSynced(syncedAt!);
    } catch (e) {
      debugPrint('aiot server refresh failed: $e');
      conn = SpyConn.error;
      RestaurantStore.instance.setAllSensorsOnline(false); // 마지막 값 유지
    } finally {
      _fetching = false;
      notifyListeners();
    }
  }

  void _apply(Map<String, dynamic>? s) {
    if (s == null) return;
    final r = byId(s['room_id'] as String? ?? '');
    if (r == null) return;
    r.camera = (s['camera'] as Map?)?.cast<String, dynamic>();
    r.updatedAt = DateTime.tryParse(s['updated_at'] as String? ?? '');
    final count = s['count'];
    if (count is num) {
      final lat = s['lat'], lng = s['lng'];
      RestaurantStore.instance.applyLive(
        r.restaurantId,
        count.toInt(),
        cap: (s['cap'] as num?)?.toInt(),
        position: lat is num && lng is num ? LatLng(lat.toDouble(), lng.toDouble()) : null,
      );
    }
  }

  /// 카메라로 찾은 몰카를 수거 → 시뮬레이터에서 귀신 검거
  Future<RemoveResult> removeCamera(SpyRoom room) async {
    try {
      final res = await _http
          .post(
            Uri.parse('$kAiotApi/api/rooms/${room.id}/actions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'type': 'camera_removed', 'clientId': clientId}),
          )
          .timeout(const Duration(seconds: 8));
      final j = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
      _apply((j['state'] as Map?)?.cast<String, dynamic>());
      notifyListeners();
      if (res.statusCode == 200) return RemoveResult.caught;
      if (res.statusCode == 409) return RemoveResult.alreadyGone;
      return RemoveResult.failed;
    } catch (e) {
      debugPrint('camera_removed failed: $e');
      return RemoveResult.failed;
    }
  }
}
