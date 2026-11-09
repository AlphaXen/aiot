import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

/// 앱 전체 상태(기기·방·장면·자동화·로그·멤버)를 보관하는 저장소.
///
/// 지금은 메모리 안의 샘플 데이터로 동작합니다. 실제 IoT 백엔드
/// (MQTT 브로커, Firebase, Supabase, 자체 REST API 등)를 붙일 때는
/// 이 클래스의 메서드 안에서 API를 호출하도록 바꾸면 두 앱 모두 그대로 동작합니다.
class HomeStore extends ChangeNotifier {
  HomeStore() {
    _seed();
  }

  static final HomeStore instance = HomeStore();

  final String homeName = '우리 집';
  final List<Room> rooms = [];
  final List<Device> devices = [];
  final List<Scene> scenes = [];
  final List<Routine> routines = [];
  final List<ActivityLog> logs = [];
  final List<Member> members = [];

  /// 최근 7일 에너지 사용량 (kWh), 오래된 날 → 오늘
  final List<double> weeklyEnergy = [];

  /// 최근 24시간 실내 평균 온도 (°C), 1시간 간격
  final List<double> hourlyTemperature = [];

  Room roomOf(Device d) => rooms.firstWhere((r) => r.id == d.roomId, orElse: () => rooms.first);
  List<Device> devicesIn(String roomId) => devices.where((d) => d.roomId == roomId).toList();
  List<Device> get favorites => devices.where((d) => d.favorite).toList();
  int get onlineCount => devices.where((d) => d.online).length;
  int get activeCount => devices.where((d) => d.isActive && d.type != DeviceType.sensor).length;
  double get currentPowerWatts => devices.where((d) => d.online && d.isOn).fold(0.0, (s, d) => s + d.powerWatts);

  Device? byId(String id) {
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  // ───────────────────────── 제어 ─────────────────────────

  void togglePower(Device d, {String actor = '홍길동'}) {
    if (!d.online || d.type.isReadOnly) return;
    if (d.type == DeviceType.doorLock) {
      d.locked = !d.locked;
      _log(d, d.locked ? '잠금' : '잠금 해제', actor: actor);
    } else if (d.type == DeviceType.blind) {
      d.level = d.level > 0 ? 0 : 100;
      _log(d, d.level > 0 ? '열림' : '닫힘', actor: actor);
    } else {
      d.isOn = !d.isOn;
      _log(d, d.isOn ? '전원 켜짐' : '전원 꺼짐', actor: actor);
    }
    notifyListeners();
  }

  void setLevel(Device d, int level, {String actor = '홍길동'}) {
    d.level = level.clamp(0, 100);
    if (d.type == DeviceType.light && d.level > 0) d.isOn = true;
    notifyListeners();
  }

  /// 슬라이더 조작이 끝났을 때 로그를 한 번만 남깁니다.
  void commitLevel(Device d, {String actor = '홍길동'}) {
    _log(d, '${_levelLabel(d.type)} ${d.level}%로 변경', actor: actor);
    notifyListeners();
  }

  void setTargetTemp(Device d, int temp, {String actor = '홍길동'}) {
    d.targetTemp = temp.clamp(16, 30);
    _log(d, '희망 온도 ${d.targetTemp}°C', actor: actor);
    notifyListeners();
  }

  void setMode(Device d, String mode, {String actor = '홍길동'}) {
    d.mode = mode;
    _log(d, '모드 변경: $mode', actor: actor);
    notifyListeners();
  }

  void toggleFavorite(Device d) {
    d.favorite = !d.favorite;
    notifyListeners();
  }

  void renameDevice(Device d, String name, {String actor = '관리자'}) {
    if (name.trim().isEmpty) return;
    final old = d.name;
    d.name = name.trim();
    _log(d, '이름 변경: $old → ${d.name}', actor: actor);
    notifyListeners();
  }

  void moveDevice(Device d, String roomId, {String actor = '관리자'}) {
    d.roomId = roomId;
    _log(d, '${roomOf(d).name}(으)로 이동', actor: actor);
    notifyListeners();
  }

  void removeDevice(Device d, {String actor = '관리자'}) {
    devices.remove(d);
    _log(d, '기기 삭제', actor: actor, level: LogLevel.warning);
    notifyListeners();
  }

  void addDevice({required String name, required DeviceType type, required String roomId, String actor = '관리자'}) {
    final d = Device(
      id: 'd${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: type,
      roomId: roomId,
      mode: type == DeviceType.airConditioner ? '냉방' : '',
      temperature: type == DeviceType.sensor ? 23.0 : null,
      humidity: type == DeviceType.sensor ? 45 : null,
      powerWatts: _defaultWatts(type),
    );
    devices.add(d);
    _log(d, '새 기기 등록', actor: actor);
    notifyListeners();
  }

  void runScene(Scene s, {String actor = '홍길동'}) {
    s.actions.forEach((id, on) {
      final d = byId(id);
      if (d == null || !d.online) return;
      if (d.type == DeviceType.doorLock) {
        d.locked = !on;
      } else if (d.type == DeviceType.blind) {
        d.level = on ? 100 : 0;
      } else {
        d.isOn = on;
      }
    });
    logs.insert(0, ActivityLog(time: DateTime.now(), deviceName: s.name, message: '장면 실행', actor: actor));
    notifyListeners();
  }

  void toggleRoutine(Routine r, {String actor = '홍길동'}) {
    r.enabled = !r.enabled;
    logs.insert(0, ActivityLog(time: DateTime.now(), deviceName: r.name, message: r.enabled ? '자동화 사용' : '자동화 중지', actor: actor));
    notifyListeners();
  }

  void runRoutine(Routine r, {String actor = '관리자'}) {
    r.lastRun = DateTime.now();
    logs.insert(0, ActivityLog(time: DateTime.now(), deviceName: r.name, message: '자동화 수동 실행', actor: actor));
    notifyListeners();
  }

  void addRoutine(Routine r) {
    routines.add(r);
    notifyListeners();
  }

  void removeRoutine(Routine r) {
    routines.remove(r);
    notifyListeners();
  }

  void setMemberRole(Member m, MemberRole role) {
    m.role = role;
    notifyListeners();
  }

  void toggleMember(Member m) {
    m.active = !m.active;
    notifyListeners();
  }

  void inviteMember(String name, String email, MemberRole role) {
    members.add(Member(id: 'm${members.length + 1}', name: name, email: email, role: role, lastActive: DateTime.now()));
    notifyListeners();
  }

  void reconnect(Device d, {String actor = '관리자'}) {
    d.online = true;
    d.lastSeen = DateTime.now();
    _log(d, '재연결 성공', actor: actor);
    notifyListeners();
  }

  void updateFirmware(Device d, {String actor = '관리자'}) {
    d.firmware = latestFirmware;
    _log(d, '펌웨어 $latestFirmware 업데이트 완료', actor: actor);
    notifyListeners();
  }

  static const latestFirmware = '2.4.1';

  // ───────────────────────── 내부 ─────────────────────────

  String _levelLabel(DeviceType t) => switch (t) {
        DeviceType.light => '밝기',
        DeviceType.tv => '볼륨',
        DeviceType.blind => '열림',
        DeviceType.airPurifier => '풍량',
        _ => '단계',
      };

  double _defaultWatts(DeviceType t) => switch (t) {
        DeviceType.light => 9,
        DeviceType.airConditioner => 850,
        DeviceType.airPurifier => 35,
        DeviceType.tv => 120,
        DeviceType.plug => 60,
        DeviceType.robotVacuum => 40,
        DeviceType.camera => 5,
        _ => 0,
      };

  void _log(Device d, String message, {String actor = '시스템', LogLevel level = LogLevel.info}) {
    logs.insert(0, ActivityLog(time: DateTime.now(), deviceName: d.name, message: message, actor: actor, level: level));
    if (logs.length > 300) logs.removeLast();
  }

  void _seed() {
    rooms.addAll(const [
      Room(id: 'living', name: '거실', icon: Icons.weekend_outlined),
      Room(id: 'kitchen', name: '주방', icon: Icons.kitchen_outlined),
      Room(id: 'bed', name: '침실', icon: Icons.bed_outlined),
      Room(id: 'study', name: '서재', icon: Icons.menu_book_outlined),
      Room(id: 'entry', name: '현관', icon: Icons.door_front_door_outlined),
    ]);

    devices.addAll([
      Device(id: 'd1', name: '거실 천장등', type: DeviceType.light, roomId: 'living', isOn: true, level: 80, favorite: true, powerWatts: 18, firmware: '2.4.1'),
      Device(id: 'd2', name: '거실 에어컨', type: DeviceType.airConditioner, roomId: 'living', isOn: true, targetTemp: 24, mode: '냉방', favorite: true, powerWatts: 850, firmware: '2.3.0'),
      Device(id: 'd3', name: '거실 TV', type: DeviceType.tv, roomId: 'living', level: 25, favorite: true, powerWatts: 120, firmware: '2.4.1'),
      Device(id: 'd4', name: '공기청정기', type: DeviceType.airPurifier, roomId: 'living', isOn: true, level: 40, favorite: true, powerWatts: 35, firmware: '2.2.5'),
      Device(id: 'd5', name: '거실 온습도', type: DeviceType.sensor, roomId: 'living', temperature: 24.6, humidity: 48, batteryPercent: 82, favorite: true, firmware: '2.4.1'),
      Device(id: 'd6', name: '거실 블라인드', type: DeviceType.blind, roomId: 'living', level: 60, powerWatts: 0, firmware: '2.1.0'),
      Device(id: 'd7', name: '주방 조명', type: DeviceType.light, roomId: 'kitchen', level: 100, powerWatts: 12, firmware: '2.4.1'),
      Device(id: 'd8', name: '커피머신 플러그', type: DeviceType.plug, roomId: 'kitchen', isOn: true, powerWatts: 1200, favorite: true, firmware: '2.4.1'),
      Device(id: 'd9', name: '침실 무드등', type: DeviceType.light, roomId: 'bed', level: 30, powerWatts: 6, firmware: '2.3.0'),
      Device(id: 'd10', name: '침실 에어컨', type: DeviceType.airConditioner, roomId: 'bed', targetTemp: 26, mode: '제습', powerWatts: 650, firmware: '2.2.5'),
      Device(id: 'd11', name: '침실 온습도', type: DeviceType.sensor, roomId: 'bed', temperature: 25.3, humidity: 55, batteryPercent: 15, firmware: '2.1.0'),
      Device(id: 'd12', name: '서재 스탠드', type: DeviceType.light, roomId: 'study', isOn: true, level: 65, powerWatts: 8, firmware: '2.4.1'),
      Device(id: 'd13', name: '모니터 플러그', type: DeviceType.plug, roomId: 'study', powerWatts: 45, online: false, lastSeen: DateTime.now().subtract(const Duration(hours: 5)), firmware: '2.0.3'),
      Device(id: 'd14', name: '현관 도어락', type: DeviceType.doorLock, roomId: 'entry', favorite: true, batteryPercent: 64, firmware: '2.3.0'),
      Device(id: 'd15', name: '현관 카메라', type: DeviceType.camera, roomId: 'entry', isOn: true, powerWatts: 5, firmware: '2.4.1'),
      Device(id: 'd16', name: '로봇청소기', type: DeviceType.robotVacuum, roomId: 'living', batteryPercent: 92, powerWatts: 40, firmware: '2.2.5'),
      Device(id: 'd17', name: '현관 센서등', type: DeviceType.light, roomId: 'entry', level: 100, powerWatts: 5, online: false, lastSeen: DateTime.now().subtract(const Duration(days: 1, hours: 3)), firmware: '1.9.8'),
    ]);

    scenes.addAll([
      Scene(id: 's1', name: '귀가', icon: Icons.home_outlined, color: const Color(0xFF3E91FF), actions: {'d1': true, 'd2': true, 'd14': false}),
      Scene(id: 's2', name: '외출', icon: Icons.directions_walk_rounded, color: const Color(0xFF26A65B), actions: {'d1': false, 'd2': false, 'd3': false, 'd7': false, 'd9': false, 'd12': false, 'd14': true, 'd16': true}),
      Scene(id: 's3', name: '영화 보기', icon: Icons.movie_outlined, color: const Color(0xFF7E57C2), actions: {'d1': false, 'd3': true, 'd6': false}),
      Scene(id: 's4', name: '취침', icon: Icons.bedtime_outlined, color: const Color(0xFF5C6BC0), actions: {'d1': false, 'd3': false, 'd9': true, 'd12': false, 'd14': true}),
    ]);

    final now = DateTime.now();
    routines.addAll([
      Routine(id: 'r1', name: '아침 기상', trigger: '매일 오전 7:00', action: '침실 무드등 켜기 · 블라인드 열기', lastRun: now.subtract(const Duration(hours: 3))),
      Routine(id: 'r2', name: '더우면 에어컨', trigger: '거실 온도 27°C 이상', action: '거실 에어컨 냉방 24°C', lastRun: now.subtract(const Duration(days: 1))),
      Routine(id: 'r3', name: '외출 시 절전', trigger: '모든 멤버가 집을 떠나면', action: '조명·TV 끄기 · 도어락 잠금'),
      Routine(id: 'r4', name: '습도 관리', trigger: '침실 습도 60% 이상', action: '침실 에어컨 제습 모드', enabled: false),
      Routine(id: 'r5', name: '해질녘 조명', trigger: '일몰 시', action: '거실 천장등 60%로 켜기', lastRun: now.subtract(const Duration(hours: 15))),
    ]);

    members.addAll([
      Member(id: 'm1', name: '홍길동', email: 'owner@example.com', role: MemberRole.owner, lastActive: now.subtract(const Duration(minutes: 2))),
      Member(id: 'm2', name: '이서연', email: 'seoyeon@example.com', role: MemberRole.admin, lastActive: now.subtract(const Duration(hours: 1))),
      Member(id: 'm3', name: '김하준', email: 'hajun@example.com', role: MemberRole.member, lastActive: now.subtract(const Duration(days: 2))),
      Member(id: 'm4', name: '방문 도우미', email: 'helper@example.com', role: MemberRole.guest, lastActive: now.subtract(const Duration(days: 9)), active: false),
    ]);

    final rnd = Random(7);
    final seedLogs = <(int, String, String, LogLevel, String)>[
      (2, '거실 천장등', '전원 켜짐', LogLevel.info, '홍길동'),
      (8, '거실 에어컨', '희망 온도 24°C', LogLevel.info, '자동화'),
      (25, '침실 온습도', '배터리 부족 (15%)', LogLevel.warning, '시스템'),
      (47, '현관 도어락', '잠금 해제', LogLevel.info, '이서연'),
      (62, '모니터 플러그', '연결 끊김', LogLevel.error, '시스템'),
      (95, '커피머신 플러그', '전원 켜짐', LogLevel.info, '홍길동'),
      (180, '아침 기상', '자동화 실행', LogLevel.info, '자동화'),
      (240, '현관 카메라', '움직임 감지', LogLevel.warning, '시스템'),
      (600, '로봇청소기', '청소 완료', LogLevel.info, '시스템'),
      (1500, '현관 센서등', '연결 끊김', LogLevel.error, '시스템'),
    ];
    for (final (min, dev, msg, lv, actor) in seedLogs) {
      logs.add(ActivityLog(time: now.subtract(Duration(minutes: min)), deviceName: dev, message: msg, level: lv, actor: actor));
    }

    weeklyEnergy.addAll([11.2, 12.8, 10.4, 13.6, 14.9, 9.7, 12.1]);
    for (var h = 0; h < 24; h++) {
      final base = 23.0 + 2.2 * sin((h - 9) / 24 * 2 * pi);
      hourlyTemperature.add(double.parse((base + rnd.nextDouble() * 0.4).toStringAsFixed(1)));
    }
  }
}

/// "3분 전" 같은 상대 시간 문구
String timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

String hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String ymdhm(DateTime t) =>
    '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')} ${hhmm(t)}';
