import 'dart:math';
import 'dart:typed_data';

import 'package:aiot/mobile/services/spycam_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// 시뮬레이터(web/index.html drawCam)와 같은 모양을 픽셀로 그려 판정을 검사합니다.
class _Frame {
  _Frame(this.w, this.h, List<int> bg) : px = Uint8List(w * h * 4) {
    for (var i = 0; i < w * h; i++) {
      px.setAll(i * 4, [...bg, 255]);
    }
  }
  final int w, h;
  final Uint8List px;

  void blend(int x, int y, List<int> c, double a) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final p = (y * w + x) * 4;
    for (var k = 0; k < 3; k++) {
      px[p + k] = (px[p + k] * (1 - a) + c[k] * a).round();
    }
  }

  void rect(double x, double y, double rw, double rh, List<int> c) {
    for (var yy = y.floor(); yy < (y + rh).ceil(); yy++) {
      for (var xx = x.floor(); xx < (x + rw).ceil(); xx++) {
        blend(xx, yy, c, 1);
      }
    }
  }

  void circle(double cx, double cy, double r, List<int> c, {double Function(double t)? alpha}) {
    for (var yy = (cy - r).floor(); yy <= (cy + r).ceil(); yy++) {
      for (var xx = (cx - r).floor(); xx <= (cx + r).ceil(); xx++) {
        final d = sqrt(pow(xx - cx, 2) + pow(yy - cy, 2));
        if (d <= r) blend(xx, yy, c, alpha?.call(d / r) ?? 1);
      }
    }
  }

  /// drawCam(c, x, y, k, on)
  void cam(double x, double y, double k, {bool on = true}) {
    if (on) circle(x + k * .42, y - k * .2, k * 2.2, [255, 40, 40], alpha: (t) => .85 * (1 - t));
    rect(x - k * .65, y - k * .4, k * 1.3, k * .8, [0x1C, 0x1F, 0x26]);
    circle(x - k * .1, y, k * .26, [0x34, 0x44, 0x5E]);
    circle(x - k * .17, y - k * .07, k * .08, [0x8F, 0xB4, 0xE8]);
    circle(x + k * .42, y - k * .2, k * .15, on ? [0xFF, 0x30, 0x30] : [0x5A, 0x1A, 0x1A]);
  }
}

const _light = [0xE9, 0xE4, 0xDA];
const _dark = [0x1E, 0x24, 0x2E];

void main() {
  for (final bg in [_light, _dark]) {
    final theme = bg == _light ? '밝은' : '어두운';

    test('$theme 배경: 켜진 몰카를 찾는다', () {
      for (final k in [8.0, 14.0, 24.0]) {
        final f = _Frame(480, 360, bg)..rect(150, 150, 180, 40, [0xB0, 0x8A, 0x63]); // 책상
        f.cam(250, 200, k);
        final d = detectHiddenCamera(f.px, f.w, f.h);
        expect(d.found, isTrue, reason: 'k=$k');
        // 조준 영역 안 좌표 → 원래 프레임 좌표
        final side = 360 * kAimFraction;
        final px = (480 - side) / 2 + d.x * side, py = (360 - side) / 2 + d.y * side;
        expect((px - (250 + k * .42)).abs(), lessThan(k * 1.2), reason: 'x k=$k');
        expect((py - (200 - k * .2)).abs(), lessThan(k * 1.2), reason: 'y k=$k');
      }
    });

    test('$theme 배경: 꺼진 LED는 몰카로 보지 않는다', () {
      final f = _Frame(480, 360, bg)..cam(240, 180, 14, on: false);
      expect(detectHiddenCamera(f.px, f.w, f.h).found, isFalse);
    });

    test('$theme 배경: 빨간 경고 배지(가로로 긴 사각형)는 무시', () {
      final f = _Frame(480, 360, bg)..rect(170, 170, 150, 16, [0xD6, 0x45, 0x45]);
      for (var x = 176; x < 312; x += 7) {
        f.rect(x.toDouble(), 174, 3, 8, [255, 255, 255]);
      }
      expect(detectHiddenCamera(f.px, f.w, f.h).found, isFalse);
    });
  }

  test('빈 화면 · 조준 영역 밖의 몰카는 무시', () {
    final f = _Frame(480, 360, _light);
    expect(detectHiddenCamera(f.px, f.w, f.h).found, isFalse);
    f.cam(30, 30, 12);
    expect(detectHiddenCamera(f.px, f.w, f.h).found, isFalse);
  });

  test('밝은 배경의 빨간 원(몸체 없음)은 무시', () {
    final f = _Frame(480, 360, _light)..circle(240, 180, 8, [0xD9, 0x43, 0x3B]);
    expect(detectHiddenCamera(f.px, f.w, f.h).found, isFalse);
  });
}
