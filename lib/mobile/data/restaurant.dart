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
  const MenuItem(this.name, this.price, {this.tag});
  final String name;
  final int price;
  final String? tag;
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
      menus: const [
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
      menus: const [
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
      menus: const [
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
      menus: const [
        MenuItem('오늘의 정식', 7000, tag: '추천'),
        MenuItem('한우 국밥', 8000),
        MenuItem('연어 포케', 8500),
      ],
      hourly: const {11: .5, 12: .9, 13: .7},
      payments: const ['카드', '교직원증'],
    ),
  ];

  Restaurant byId(String id) => restaurants.firstWhere((r) => r.id == id);

  /// 혼잡도 새로고침 (목업: 같은 단계 안에서 좌석 수만 조금씩 변동)
  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (final r in restaurants) {
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

  /// AI 추천.
  /// TODO(개발 단계): 지금은 무조건 오렌지식당을 반환합니다.
  /// 추후 [from] 위치와의 거리 + 혼잡도 점수로 가장 덜 혼잡하고 가까운 식당을 고르도록 교체하세요.
  Restaurant recommend(LatLng from) => byId('orange');
}
