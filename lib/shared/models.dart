import 'package:flutter/material.dart';

/// 지원하는 기기 종류
enum DeviceType {
  light('조명', Icons.lightbulb_outline_rounded, Color(0xFFFFB300)),
  airConditioner('에어컨', Icons.ac_unit_rounded, Color(0xFF3E91FF)),
  airPurifier('공기청정기', Icons.air_rounded, Color(0xFF00B8A9)),
  tv('TV', Icons.tv_rounded, Color(0xFF5C6BC0)),
  plug('스마트 플러그', Icons.power_outlined, Color(0xFF26A65B)),
  doorLock('도어락', Icons.lock_outline_rounded, Color(0xFF7E57C2)),
  sensor('온습도 센서', Icons.thermostat_rounded, Color(0xFFFF7043)),
  camera('카메라', Icons.videocam_outlined, Color(0xFF546E7A)),
  robotVacuum('로봇청소기', Icons.cleaning_services_outlined, Color(0xFF8D6E63)),
  blind('블라인드', Icons.blinds_outlined, Color(0xFF26A69A));

  const DeviceType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  /// 전원 on/off 개념이 없는 기기
  bool get isReadOnly => this == DeviceType.sensor;
}

class Room {
  const Room({required this.id, required this.name, required this.icon});
  final String id;
  final String name;
  final IconData icon;
}

class Device {
  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.roomId,
    this.isOn = false,
    this.online = true,
    this.level = 50,
    this.targetTemp = 24,
    this.mode = '',
    this.favorite = false,
    this.firmware = '1.0.0',
    this.batteryPercent,
    this.powerWatts = 0,
    this.temperature,
    this.humidity,
    this.locked = true,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  final String id;
  String name;
  final DeviceType type;
  String roomId;
  bool isOn;
  bool online;

  /// 밝기/풍량/볼륨/열림 정도 등 0~100
  int level;

  /// 에어컨 희망 온도
  int targetTemp;

  /// 운전 모드 (냉방, 제습, 자동 ...)
  String mode;
  bool favorite;
  String firmware;
  int? batteryPercent;
  double powerWatts;
  double? temperature;
  double? humidity;
  bool locked;
  DateTime lastSeen;

  /// 타일/목록에 표시할 상태 문구
  String get statusText {
    if (!online) return '연결 끊김';
    switch (type) {
      case DeviceType.sensor:
        return '${temperature?.toStringAsFixed(1)}°C · ${humidity?.toStringAsFixed(0)}%';
      case DeviceType.doorLock:
        return locked ? '잠김' : '열림';
      case DeviceType.light:
        return isOn ? '켜짐 · $level%' : '꺼짐';
      case DeviceType.airConditioner:
        return isOn ? '$mode · $targetTemp°C' : '꺼짐';
      case DeviceType.blind:
        return level == 0 ? '닫힘' : '$level% 열림';
      case DeviceType.plug:
        return isOn ? '켜짐 · ${powerWatts.toStringAsFixed(0)}W' : '꺼짐';
      case DeviceType.robotVacuum:
        return isOn ? '청소 중' : '충전 중 · ${batteryPercent ?? 100}%';
      default:
        return isOn ? '켜짐' : '꺼짐';
    }
  }

  /// 기기가 "활성" 상태로 보이는지 (아이콘 색상 강조용)
  bool get isActive {
    if (!online) return false;
    switch (type) {
      case DeviceType.sensor:
        return true;
      case DeviceType.doorLock:
        return !locked;
      case DeviceType.blind:
        return level > 0;
      default:
        return isOn;
    }
  }
}

class Scene {
  Scene({required this.id, required this.name, required this.icon, required this.color, required this.actions});
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  /// 실행 시 적용할 기기 상태: deviceId -> 켜짐 여부
  final Map<String, bool> actions;
}

class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.trigger,
    required this.action,
    this.enabled = true,
    this.lastRun,
  });
  final String id;
  String name;
  String trigger;
  String action;
  bool enabled;
  DateTime? lastRun;
}

enum LogLevel { info, warning, error }

class ActivityLog {
  ActivityLog({required this.time, required this.deviceName, required this.message, this.level = LogLevel.info, this.actor = '시스템'});
  final DateTime time;
  final String deviceName;
  final String message;
  final LogLevel level;
  final String actor;
}

enum MemberRole {
  owner('소유자'),
  admin('관리자'),
  member('멤버'),
  guest('게스트');

  const MemberRole(this.label);
  final String label;
}

class Member {
  Member({required this.id, required this.name, required this.email, required this.role, required this.lastActive, this.active = true});
  final String id;
  final String name;
  final String email;
  MemberRole role;
  DateTime lastActive;
  bool active;
}
