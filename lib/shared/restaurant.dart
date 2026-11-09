import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// 혼잡도 3단계 (원형 아이콘 테두리 색으로 표시)
enum Congestion {
  relaxed('여유', Color(0xFF22C55E), Color(0xFF16A34A)),
  busy('혼잡', Color(0xFFFACC15), Color(0xFFCA8A04)),
  veryBusy('매우 혼잡', Color(0xFFEF4444), Color(0xFFDC2626));

  const Congestion(this.label, this.color, this.textColor);
  final String label;

  /// 테두리·막대 등 면 색
  final Color color;

  /// 흰 배경 위 글자용(노랑은 가독성이 낮아 한 톤 진하게)
  final Color textColor;

  static Congestion fromRatio(double r) {
    if (r >= 0.8) return Congestion.veryBusy;
    if (r >= 0.5) return Congestion.busy;
    return Congestion.relaxed;
  }
}

class MenuItem {
  MenuItem(this.name, this.price, {this.tag});
  String name;
  int price;
  String? tag;

  /// 품절 여부 (관리자 화면에서 변경)
  bool soldOut = false;
}

class Restaurant {
  Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.place,
    required this.position,
    required this.openHours,
    required this.openHour,
    required this.closeHour,
    required this.seats,
    required this.occupied,
    required this.menus,
    required this.hourly,
    this.payments = const ['카드', '학생증'],
  });

  final String id;
  final String name;
  final String category;
  final IconData icon;

  /// 건물·층 등 교내 위치 설명
  final String place;
  final LatLng position;
  final String openHours;
  final int openHour;
  final int closeHour;
  final int seats;
  int occupied;
  final List<MenuItem> menus;

  /// 시간대별 평균 혼잡률 (key: 시, value: 0~1)
  final Map<int, double> hourly;
  final List<String> payments;
  bool favorite = false;

  /// 혼잡도 센서 연결 상태 (끊기면 마지막 값 유지)
  bool sensorOnline = true;

  double get ratio => occupied / seats;
  Congestion get congestion => Congestion.fromRatio(ratio);

  /// 좌석 점유율로 추정한 대기 시간(분)
  int get waitMinutes => ((ratio - 0.45) * 40).clamp(0, 30).round();

  bool isOpenAt(DateTime t) => t.hour >= openHour && t.hour < closeHour;
}

/// 식당 혼잡도 저장소.
/// 개발 단계라 목업 데이터를 사용합니다. 실제 IoT 센서/서버 연동 시 [refresh]만 교체하면 됩니다.
class RestaurantStore extends ChangeNotifier {
  RestaurantStore._();
  static final instance = RestaurantStore._();

  /// TODO: 실제 캠퍼스 좌표로 교체하세요. (GPS 실패 시 기본 위치로도 사용)
  static const campusCenter = LatLng(37.5665, 126.9780);

  final _rand = Random();
  DateTime updatedAt = DateTime.now();

  final List<Restaurant> restaurants = [
    Restaurant(
      id: 'student',
      name: '학생식당',
      category: '한식 · 백반',
      icon: Icons.rice_bowl_rounded,
      place: '학생회관 1층',
      position: const LatLng(37.5672, 126.9772),
      openHours: '11:00 - 19:00',
      openHour: 11,
      closeHour: 19,
      seats: 220,
      occupied: 198,
      menus: [
        MenuItem('제육볶음 정식', 5500, tag: '인기'),
        MenuItem('된장찌개 백반', 5000),
        MenuItem('돈까스 카레', 5500),
        MenuItem('비빔밥', 4500, tag: '가성비'),
      ],
      hourly: const {11: .45, 12: .95, 13: .85, 14: .4, 15: .2, 16: .2, 17: .55, 18: .8},
    ),
    Restaurant(
      id: 'orange',
      name: '오렌지식당',
      category: '분식 · 덮밥',
      icon: Icons.ramen_dining_rounded,
      place: '공학관 지하 1층',
      position: const LatLng(37.5659, 126.9788),
      openHours: '10:30 - 20:00',
      openHour: 10,
      closeHour: 20,
      seats: 120,
      occupied: 34,
      menus: [
        MenuItem('치즈 김치볶음밥', 5500, tag: '인기'),
        MenuItem('참치마요 덮밥', 5000),
        MenuItem('라볶이', 4500),
        MenuItem('김밥 + 우동 세트', 6000, tag: '세트'),
      ],
      hourly: const {10: .15, 11: .3, 12: .65, 13: .5, 14: .25, 15: .15, 16: .2, 17: .35, 18: .5, 19: .3},
    ),
    Restaurant(
      id: 'nyburger',
      name: '뉴욕버거',
      category: '버거 · 양식',
      icon: Icons.lunch_dining_rounded,
      place: '중앙도서관 옆',
      position: const LatLng(37.5677, 126.9790),
      openHours: '10:00 - 21:00',
      openHour: 10,
      closeHour: 21,
      seats: 60,
      occupied: 40,
      menus: [
        MenuItem('클래식 치즈버거 세트', 7900, tag: '인기'),
        MenuItem('더블 베이컨 버거', 8900),
        MenuItem('치킨 텐더 세트', 7500),
        MenuItem('감자튀김', 2500),
      ],
      hourly: const {10: .1, 11: .35, 12: .8, 13: .75, 14: .45, 15: .3, 16: .35, 17: .5, 18: .7, 19: .5, 20: .3},
    ),
    Restaurant(
      id: 'faculty',
      name: '교수식당',
      category: '정식 · 일품',
      icon: Icons.restaurant_rounded,
      place: '본관 2층',
      position: const LatLng(37.5668, 126.9766),
      openHours: '11:30 - 14:00',
      openHour: 11,
      closeHour: 14,
      seats: 80,
      occupied: 70,
      menus: [
        MenuItem('오늘의 정식', 7000, tag: '추천'),
        MenuItem('한우 국밥', 8000),
        MenuItem('연어 포케', 8500),
      ],
      hourly: const {11: .5, 12: .9, 13: .7},
      payments: const ['카드', '교직원증'],
    ),
  ];

  Restaurant byId(String id) => restaurants.firstWhere((r) => r.id == id);

  int get totalOccupied => restaurants.fold(0, (a, r) => a + r.occupied);
  int get totalSeats => restaurants.fold(0, (a, r) => a + r.seats);

  /// 혼잡도 새로고침 (목업: 같은 단계 안에서 좌석 수만 조금씩 변동)
  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (final r in restaurants) {
      if (!r.sensorOnline) continue;
      final next = (r.occupied + _rand.nextInt(9) - 4).clamp(0, r.seats);
      if (Congestion.fromRatio(next / r.seats) == r.congestion) r.occupied = next;
    }
    updatedAt = DateTime.now();
    notifyListeners();
  }

  void toggleFavorite(Restaurant r) {
    r.favorite = !r.favorite;
    notifyListeners();
  }

  // ---- 관리자 기능 ----

  /// 좌석 사용 수 수동 보정
  void setOccupied(Restaurant r, int occupied) {
    r.occupied = occupied.clamp(0, r.seats);
    updatedAt = DateTime.now();
    notifyListeners();
  }

  void setSensorOnline(Restaurant r, bool online) {
    r.sensorOnline = online;
    notifyListeners();
  }

  void addMenu(Restaurant r, MenuItem m) {
    r.menus.add(m);
    notifyListeners();
  }

  void removeMenu(Restaurant r, MenuItem m) {
    r.menus.remove(m);
    notifyListeners();
  }

  void updateMenu(MenuItem m, {String? name, int? price, bool? soldOut}) {
    if (name != null) m.name = name;
    if (price != null) m.price = price;
    if (soldOut != null) m.soldOut = soldOut;
    notifyListeners();
  }

  // ---- AI 추천 ----

  /// 개발 단계: 추천 결과를 이 식당으로 고정 (null 이면 점수 계산 사용)
  String? fixedRecommendId = 'orange';

  /// 점수 계산에서 혼잡도 비중 (0~1, 나머지는 거리)
  double congestionWeight = 0.6;

  /// 이 거리(m) 이상은 거리 점수 최하
  double maxDistanceMeters = 800;

  void updateAiSettings({Object? fixedId = _keep, double? weight, double? maxDistance}) {
    if (fixedId != _keep) fixedRecommendId = fixedId as String?;
    if (weight != null) congestionWeight = weight;
    if (maxDistance != null) maxDistanceMeters = maxDistance;
    notifyListeners();
  }

  /// 낮을수록 좋은 점수 (혼잡도 · 거리 가중합). 영업 중이 아니면 null.
  double? score(Restaurant r, LatLng from) {
    if (!r.isOpenAt(DateTime.now())) return null;
    final d = const Distance().as(LengthUnit.Meter, from, r.position);
    final dist = (d / maxDistanceMeters).clamp(0.0, 1.0);
    return congestionWeight * r.ratio + (1 - congestionWeight) * dist;
  }

  /// 점수가 좋은 순서 (영업 종료 식당은 맨 뒤)
  List<(Restaurant, double?)> ranking(LatLng from) {
    final list = [for (final r in restaurants) (r, score(r, from))];
    list.sort((a, b) => (a.$2 ?? 99).compareTo(b.$2 ?? 99));
    return list;
  }

  /// AI 추천. 개발 단계 기본값은 [fixedRecommendId] = 오렌지식당 고정.
  /// 고정을 해제하면 [from] 위치 기준 혼잡도 · 거리 점수가 가장 좋은 식당을 고릅니다.
  Restaurant recommend(LatLng from) {
    final fixed = fixedRecommendId;
    if (fixed != null) return byId(fixed);
    return ranking(from).first.$1;
  }
}

const _keep = Object();
