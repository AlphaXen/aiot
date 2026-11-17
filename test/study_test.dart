import 'package:aiot/mobile/mobile_app.dart';
import 'package:aiot/shared/restaurant.dart';
import 'package:aiot/shared/study.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Restaurant _r(String id, {int seats = 50, int occupied = 10, EnvReading? env}) {
  final base = RestaurantStore.instance.byId(id);
  return Restaurant(
    id: base.id,
    name: base.name,
    category: base.category,
    icon: base.icon,
    place: base.place,
    position: base.position,
    openHours: base.openHours,
    openHour: base.openHour,
    closeHour: base.closeHour,
    seats: seats,
    occupied: occupied,
    menus: const [],
    hourly: const {},
  )..env = env;
}

const _quiet = EnvReading(noise: 38, co2: 650, temp: 22, hum: 50);

void main() {
  test('조용하고 빈 자리 많고 공기 좋으면 매우 쾌적 (100점)', () {
    final c = StudyComfort.of(_r('faculty', seats: 50, occupied: 5, env: _quiet));
    expect(c.score, 100);
    expect(c.level, StudyLevel.great);
    expect(c.blocker, isNull);
    expect(c.summary, contains('조용'));
  });

  test('65 dB 이상이면 다른 조건이 좋아도 비추천', () {
    final c = StudyComfort.of(
      _r('student', seats: 60, occupied: 6, env: const EnvReading(noise: 72, co2: 600, temp: 22, hum: 50)),
    );
    expect(c.level, StudyLevel.poor);
    expect(c.blocker, contains('시끄러워'));
  });

  test('빈 좌석이 없으면 비추천 (정원 초과 포함)', () {
    expect(StudyComfort.of(_r('orange', seats: 40, occupied: 40, env: _quiet)).level, StudyLevel.poor);
    expect(StudyComfort.of(_r('orange', seats: 40, occupied: 45, env: _quiet)).emptySeats, 0);
  });

  test('CO₂가 높으면 점수가 내려가고 이유에 졸림 표시', () {
    final good = StudyComfort.of(_r('faculty', env: _quiet));
    final stuffy = StudyComfort.of(_r('faculty', env: const EnvReading(noise: 38, co2: 1600, temp: 22, hum: 50)));
    expect(stuffy.score, lessThan(good.score));
    expect(stuffy.summary, contains('졸릴'));
  });

  test('센서 값이 없으면 빈 좌석만으로 계산', () {
    final c = StudyComfort.of(_r('faculty', seats: 50, occupied: 5));
    expect(c.hasSensors, isFalse);
    expect(c.factors.length, 1);
    expect(c.summary, contains('센서'));
  });

  test('순위: 비추천은 뒤로, 나머지는 점수 높은 순', () {
    final ranked = StudyComfort.rank([
      _r('student', env: const EnvReading(noise: 75, co2: 600, temp: 22, hum: 50)),
      _r('orange', env: const EnvReading(noise: 52, co2: 900, temp: 25, hum: 55)),
      _r('faculty', env: _quiet),
    ]);
    expect(ranked.map((c) => c.restaurant.id).toList(), ['faculty', 'orange', 'student']);
  });

  test('서버 sensors JSON 파싱', () {
    expect(EnvReading.fromJson({'noise': 40, 'co2': 700, 'temp': 22.5, 'hum': 48}), const EnvReading(noise: 40, co2: 700, temp: 22.5, hum: 48));
    expect(EnvReading.fromJson({'noise': 40}), isNull);
    expect(EnvReading.fromJson(null), isNull);
  });

  testWidgets('공부 공간 탭: 추천 카드와 4곳 쾌적도 표시, 넘침 없음', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final st = RestaurantStore.instance;
    st.applyEnv('faculty', _quiet, DateTime.now(), {'noise'});
    st.applyEnv('student', const EnvReading(noise: 72, co2: 1200, temp: 25, hum: 55), DateTime.now(), {});
    addTearDown(() {
      st.applyEnv('faculty', null, null, {});
      st.applyEnv('student', null, null, {});
    });

    await tester.pumpWidget(const MobileApp());
    expect(find.textContaining('공부하기 좋은 곳'), findsOneWidget); // 홈 배너
    await tester.tap(find.text('공부 공간'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('조용히 공부할 곳 찾기'), findsOneWidget);
    expect(find.text('지금 공부하기 가장 좋은 곳'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
