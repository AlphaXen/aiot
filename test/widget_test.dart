import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiot/admin/admin_app.dart';
import 'package:aiot/shared/restaurant.dart';
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

  testWidgets('관리자 대시보드: 개요와 모든 페이지', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdminApp());
    expect(find.text('식당별 실시간 혼잡도'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final label in ['식당 · 혼잡도', '메뉴 관리', 'IoT 센서', 'AI 추천 설정', '이용 통계', '활동 로그', '대시보드']) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('관리자: 품절 처리가 공유 데이터에 반영', (tester) async {
    final st = RestaurantStore.instance;
    final m = st.byId('orange').menus.first;
    st.updateMenu(m, soldOut: true);
    expect(m.soldOut, isTrue);
    st.updateMenu(m, soldOut: false);
  });

  test('AI 추천: 고정 해제 시 점수 기반 선택', () {
    final st = RestaurantStore.instance;
    expect(st.fixedRecommendId, 'orange');
    st.updateAiSettings(fixedId: null);
    final ranked = st.ranking(RestaurantStore.campusCenter);
    expect(st.recommend(RestaurantStore.campusCenter), ranked.first.$1);
    st.updateAiSettings(fixedId: 'orange');
    expect(st.recommend(RestaurantStore.campusCenter).id, 'orange');
  });
}
