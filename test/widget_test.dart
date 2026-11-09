import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiot/admin/admin_app.dart';
import 'package:aiot/mobile/mobile_app.dart';
import 'package:aiot/shared/home_store.dart';

void main() {
  testWidgets('모바일 앱: 즐겨찾기 화면과 탭 이동', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MobileApp());
    expect(find.text('즐겨찾기'), findsWidgets);
    expect(find.text('거실 천장등'), findsOneWidget);

    await tester.tap(find.text('기기').last);
    await tester.pumpAndSettle();
    expect(find.text('거실'), findsWidgets);
  });

  testWidgets('모바일 앱: 전원 버튼으로 기기 끄기', (tester) async {
    final d = HomeStore.instance.byId('d1')!;
    d.isOn = true;
    HomeStore.instance.togglePower(d);
    expect(d.isOn, isFalse);
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
