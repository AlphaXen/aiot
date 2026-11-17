import 'package:aiot/mobile/mobile_app.dart';
import 'package:aiot/shared/restaurant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('식당 좌표 (서버 연결 전 기본값)', () {
    final st = RestaurantStore.instance;
    expect(st.byId('student').position, const LatLng(36.797520, 127.077506));
    expect(st.byId('orange').position, const LatLng(36.798259, 127.072388));
    expect(st.byId('faculty').position, const LatLng(36.800239, 127.074679));
    expect(st.byId('nyburger').position, st.byId('faculty').position); // 같은 건물, 층만 다름
  });

  test('같은 좌표의 식당은 한 묶음 (교수식당 + 뉴욕버거)', () {
    final groups = RestaurantStore.groupByPosition(RestaurantStore.instance.restaurants);
    expect(groups.length, 3);
    final pair = groups.firstWhere((g) => g.length == 2).map((r) => r.id).toSet();
    expect(pair, {'faculty', 'nyburger'});
  });

  test('서버 좌표로 덮어쓰기', () {
    final st = RestaurantStore.instance;
    final o = st.byId('orange');
    final before = o.position;
    st.applyLive('orange', o.occupied, cap: o.seats, position: const LatLng(36.7983, 127.0724));
    expect(o.position, const LatLng(36.7983, 127.0724));
    st.applyLive('orange', o.occupied, cap: o.seats, position: before);
  });

  testWidgets('지도 탭: 겹치는 두 식당은 마커 하나 · 누르면 선택 시트 · 고르면 카드 표시', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MobileApp());
    await tester.tap(find.text('지도'));
    await tester.pump(const Duration(seconds: 1));

    final group = find.text('뉴욕버거 · 교수식당');
    expect(group, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(group);
    await tester.pumpAndSettle();
    expect(find.text('이 건물의 식당 2곳'), findsOneWidget);

    await tester.tap(find.text('뉴욕버거').last);
    await tester.pumpAndSettle();
    expect(find.text('이 건물의 식당 2곳'), findsNothing);
    // 선택하면 이름표가 뉴욕버거로 바뀌고 아래에 식당 카드가 뜸
    expect(find.text('뉴욕버거 · 교수식당'), findsNothing);
    expect(find.text('뉴욕버거'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
