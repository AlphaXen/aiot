import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiot/admin/admin_app.dart';

/// 관리자 페이지가 좁은 화면(태블릿 · 폰)에서도 넘침 없이 그려지는지 확인
void main() {
  for (final size in const [Size(390, 844), Size(820, 1180), Size(1100, 800)]) {
    testWidgets('관리자 레이아웃 ${size.width.toInt()}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AdminApp());
      expect(tester.takeException(), isNull, reason: '대시보드');

      final labels = ['식당 · 혼잡도', '메뉴 관리', 'IoT 센서', 'AI 추천 설정', '이용 통계', '활동 로그'];
      for (final label in labels) {
        if (size.width < 1000) {
          await tester.tap(find.byTooltip('메뉴'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
      }
    });
  }
}
