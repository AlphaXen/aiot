import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiot/admin/admin_app.dart';
import 'package:aiot/mobile/data/restaurant.dart';
import 'package:aiot/mobile/mobile_app.dart';
import 'package:aiot/mobile/screens/restaurant_detail_screen.dart';

void main() {
  testWidgets('사용자 앱: 홈에 AI 추천과 4개 식당 혼잡도 표시', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MobileApp());
    expect(find.text('내 위치로 추천받기'), findsOneWidget);
    for (final name in ['학생식당', '오렌지식당', '뉴욕버거', '교수식당']) {
      expect(find.text(name), findsWidgets, reason: name);
    }
  });

  test('혼잡도 단계와 AI 추천(개발 단계: 오렌지식당 고정)', () {
    expect(Congestion.fromRatio(0.3), Congestion.relaxed);
    expect(Congestion.fromRatio(0.6), Congestion.busy);
    expect(Congestion.fromRatio(0.9), Congestion.veryBusy);
    final store = RestaurantStore.instance;
    expect(store.recommend(RestaurantStore.campusCenter).name, '오렌지식당');
    expect(store.byId('orange').congestion, Congestion.relaxed);
    expect(store.byId('student').congestion, Congestion.veryBusy);
  });

  testWidgets('사용자 앱: 식당 상세 페이지', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: RestaurantDetailScreen(restaurant: RestaurantStore.instance.byId('orange'))));
    expect(find.text('실시간 혼잡도'), findsOneWidget);
    expect(find.text('시간대별 혼잡도'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('관리자 대시보드: 개요와 기기 페이지', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdminApp());
    expect(find.text('에너지 사용량'), findsOneWidget);

    await tester.tap(find.text('기기').first);
    await tester.pumpAndSettle();
    expect(find.text('기기 추가'), findsOneWidget);

    for (final label in ['장소 · 방', '자동화', '멤버', '활동 로그', '펌웨어']) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });
}
