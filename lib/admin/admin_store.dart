import 'package:flutter/material.dart';

import '../shared/restaurant.dart';

enum SensorKind {
  entrance('출입 카운터', Icons.sensor_door_outlined),
  seat('좌석 센서', Icons.event_seat_outlined),
  camera('혼잡도 카메라', Icons.videocam_outlined),
  gateway('게이트웨이', Icons.router_outlined);

  const SensorKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Sensor {
  Sensor({
    required this.id,
    required this.restaurantId,
    required this.kind,
    required this.name,
    required this.firmware,
    this.online = true,
    this.battery,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  final String id;
  final String restaurantId;
  final SensorKind kind;
  final String name;
  String firmware;
  bool online;
  int? battery;
  DateTime lastSeen;
}

enum LogLevel {
  info('정보'),
  warning('경고'),
  error('오류');

  const LogLevel(this.label);
  final String label;
}

class AdminLog {
  AdminLog(this.level, this.target, this.message, {this.actor = '시스템', DateTime? time}) : time = time ?? DateTime.now();
  final LogLevel level;
  final String target;
  final String message;
  final String actor;
  final DateTime time;
}

/// 관리자 전용 목업 데이터 (센서 · 로그 · 통계).
/// 식당/혼잡도/메뉴 데이터는 사용자 앱과 같은 [RestaurantStore]를 사용합니다.
class AdminStore extends ChangeNotifier {
  AdminStore._() {
    final st = RestaurantStore.instance;
    // 센서 상태가 바뀌면 식당 혼잡도 '센서 연결' 표시도 같이 갱신
    for (final r in st.restaurants) {
      st.setSensorOnline(r, sensorsOf(r.id).where((s) => s.kind != SensorKind.gateway).every((s) => s.online));
    }
  }
  static final instance = AdminStore._();

  static const latestFirmware = '2.4.1';
  static const adminName = '김관리';
  static const adminRole = '학생복지팀';

  static DateTime _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes));

  final List<Sensor> sensors = [
    Sensor(id: 's1', restaurantId: 'student', kind: SensorKind.entrance, name: '학생식당 정문 카운터', firmware: '2.4.1'),
    Sensor(id: 's2', restaurantId: 'student', kind: SensorKind.entrance, name: '학생식당 후문 카운터', firmware: '2.3.0', battery: 64),
    Sensor(id: 's3', restaurantId: 'student', kind: SensorKind.camera, name: '학생식당 홀 카메라', firmware: '2.4.1'),
    Sensor(id: 's4', restaurantId: 'orange', kind: SensorKind.entrance, name: '오렌지식당 출입 카운터', firmware: '2.4.1', battery: 88),
    Sensor(id: 's5', restaurantId: 'orange', kind: SensorKind.seat, name: '오렌지식당 좌석 센서 A', firmware: '2.4.1', battery: 71),
    Sensor(id: 's6', restaurantId: 'orange', kind: SensorKind.seat, name: '오렌지식당 좌석 센서 B', firmware: '2.3.0', battery: 15),
    Sensor(id: 's7', restaurantId: 'nyburger', kind: SensorKind.entrance, name: '뉴욕버거 출입 카운터', firmware: '2.4.1', battery: 52),
    Sensor(id: 's8', restaurantId: 'nyburger', kind: SensorKind.camera, name: '뉴욕버거 매장 카메라', firmware: '2.2.4'),
    Sensor(id: 's9', restaurantId: 'faculty', kind: SensorKind.entrance, name: '교수식당 출입 카운터', firmware: '2.4.1', battery: 93),
    Sensor(id: 's10', restaurantId: 'faculty', kind: SensorKind.seat, name: '교수식당 좌석 센서', firmware: '2.3.0', battery: 40),
    Sensor(id: 'g1', restaurantId: 'student', kind: SensorKind.gateway, name: '학생회관 게이트웨이', firmware: '2.4.1'),
    Sensor(id: 'g2', restaurantId: 'orange', kind: SensorKind.gateway, name: '공학관 게이트웨이', firmware: '2.4.1'),
  ]..firstWhere((s) => s.id == 's8').online = false;

  late final List<AdminLog> logs = [
    AdminLog(LogLevel.warning, '학생식당', '혼잡도 "매우 혼잡" 단계 진입 (좌석 90%)', time: _ago(4)),
    AdminLog(LogLevel.info, '오렌지식당', 'AI 추천 식당으로 안내됨 (오늘 132회)', time: _ago(9)),
    AdminLog(LogLevel.error, '뉴욕버거 매장 카메라', '센서 연결 끊김', time: _ago(18)),
    AdminLog(LogLevel.warning, '오렌지식당 좌석 센서 B', '배터리 부족 (15%)', time: _ago(35)),
    AdminLog(LogLevel.info, '교수식당', '오늘의 메뉴 등록 (3개)', actor: adminName, time: _ago(62)),
    AdminLog(LogLevel.info, '학생식당', '오늘의 메뉴 등록 (4개)', actor: adminName, time: _ago(75)),
    AdminLog(LogLevel.info, '공학관 게이트웨이', '펌웨어 2.4.1 업데이트 완료', time: _ago(140)),
  ];

  /// 최근 7일 식당별 방문자 수 (마지막이 오늘)
  final Map<String, List<double>> weeklyVisitors = {
    'student': [1820, 1910, 1765, 1990, 1640, 420, 1710],
    'orange': [780, 820, 760, 845, 700, 260, 810],
    'nyburger': [540, 600, 580, 610, 690, 380, 560],
    'faculty': [210, 230, 220, 240, 190, 0, 205],
  };

  /// 최근 7일 AI 추천 요청 수
  final List<double> weeklyAiRequests = [96, 112, 104, 128, 140, 38, 132];

  Sensor? byId(String id) => sensors.where((s) => s.id == id).firstOrNull;
  List<Sensor> sensorsOf(String restaurantId) => sensors.where((s) => s.restaurantId == restaurantId).toList();
  int get onlineSensors => sensors.where((s) => s.online).length;
  int get alertCount => logs.where((l) => l.level != LogLevel.info).length;

  void log(AdminLog l) {
    logs.insert(0, l);
    notifyListeners();
  }

  void _syncRestaurant(String restaurantId) {
    final st = RestaurantStore.instance;
    st.setSensorOnline(st.byId(restaurantId), sensorsOf(restaurantId).where((s) => s.kind != SensorKind.gateway).every((s) => s.online));
  }

  void reconnect(Sensor s) {
    s.online = true;
    s.lastSeen = DateTime.now();
    _syncRestaurant(s.restaurantId);
    log(AdminLog(LogLevel.info, s.name, '센서 재연결됨', actor: adminName));
  }

  void updateFirmware(Sensor s) {
    s.firmware = latestFirmware;
    log(AdminLog(LogLevel.info, s.name, '펌웨어 $latestFirmware 업데이트 완료', actor: adminName));
  }

  void replaceBattery(Sensor s) {
    s.battery = 100;
    log(AdminLog(LogLevel.info, s.name, '배터리 교체 (100%)', actor: adminName));
  }
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  return '${d.inDays}일 전';
}

String won(int v) => '${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}원';

/// 최근 7일 요일 라벨 (마지막은 '오늘')
List<String> last7DayLabels() {
  final now = DateTime.now();
  const dow = ['월', '화', '수', '목', '금', '토', '일'];
  return [for (var i = 6; i >= 1; i--) dow[now.subtract(Duration(days: i)).weekday - 1], '오늘'];
}
