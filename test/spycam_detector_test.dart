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
const _darkFloor = [0x3B, 0x32, 0x26]; // 테스터 어두운 테마 바닥 (몰카가 놓이는 곳)
const _red = [0xFF, 0x30, 0x30];
const _body = [0x1C, 0x1F, 0x26];
const _lens = [0x34, 0x44, 0x5E];

bool _detect(_Frame f) => detectHiddenCamera(f.px, f.w, f.h).found;

void main() {
  for (final (theme, bg) in [('밝은', _light), ('어두운', _dark), ('어두운 바닥', _darkFloor)]) {
    group('$theme 배경', () {
      test('켜진 몰카를 찾고 몸체 위치를 돌려준다', () {
        for (final k in [8.0, 14.0, 24.0, 40.0]) {
          final f = _Frame(480, 360, bg)..rect(150, 150, 180, 40, [0xB0, 0x8A, 0x63]); // 책상
          f.cam(250, 200, k);
          final d = detectHiddenCamera(f.px, f.w, f.h);
          expect(d.found, isTrue, reason: 'k=$k');
          final side = 360 * kAimFraction;
          final px = (480 - side) / 2 + d.x * side, py = (360 - side) / 2 + d.y * side;
          expect((px - 250).abs(), lessThan(k * 0.3 + 1), reason: 'x k=$k');
          expect((py - 200).abs(), lessThan(k * 0.3 + 1), reason: 'y k=$k');
        }
      });

      test('꺼진 LED(깜박임 꺼진 순간)는 몰카로 보지 않는다', () {
        expect(_detect(_Frame(480, 360, bg)..cam(240, 180, 14, on: false)), isFalse);
      });

      test('빨간 원 · 빨간 경고 배지만 있으면 무시', () {
        final f = _Frame(480, 360, bg)
          ..circle(200, 160, 10, _red)
          ..circle(270, 200, 30, [255, 40, 40], alpha: (t) => .85 * (1 - t))
          ..rect(170, 230, 150, 16, [0xD6, 0x45, 0x45]);
        expect(_detect(f), isFalse);
      });

      test('빨간 불빛 + 검은 사각형이어도 렌즈가 없으면 무시', () {
        const k = 16.0;
        final f = _Frame(480, 360, bg)
          ..circle(240 + k * .42, 180 - k * .2, k * 2.2, [255, 40, 40], alpha: (t) => .85 * (1 - t))
          ..rect(240 - k * .65, 180 - k * .4, k * 1.3, k * .8, _body)
          ..circle(240 + k * .42, 180 - k * .2, k * .15, _red);
        expect(_detect(f), isFalse);
      });

      test('LED가 렌즈 왼쪽에 있는 등 배치가 다르면 무시', () {
        const k = 16.0, x = 240.0, y = 180.0;
        final f = _Frame(480, 360, bg)
          ..circle(x - k * .42, y - k * .2, k * 2.2, [255, 40, 40], alpha: (t) => .85 * (1 - t))
          ..rect(x - k * .65, y - k * .4, k * 1.3, k * .8, _body)
          ..circle(x + k * .1, y, k * .26, _lens)
          ..circle(x - k * .42, y - k * .2, k * .15, _red);
        expect(_detect(f), isFalse);
      });

      test('세로로 긴 검은 물체(폰 등) + 빨간 불빛은 무시', () {
        const k = 16.0, x = 240.0, y = 180.0;
        final f = _Frame(480, 360, bg)
          ..circle(x, y, k * 2.2, [255, 40, 40], alpha: (t) => .85 * (1 - t))
          ..rect(x - k * .4, y - k * .9, k * .8, k * 1.8, _body)
          ..circle(x, y, k * .2, _lens)
          ..circle(x + k * .2, y - k * .7, k * .12, _red);
        expect(_detect(f), isFalse);
      });
    });
  }

  test('폰으로 모니터를 찍은 것처럼 흐림 · 노이즈 · 밝기 변화가 있어도 찾는다', () {
    final rnd = Random(3);
    for (final (bg, k, gain, lift) in [
      (_light, 14.0, 0.9, 10),
      (_light, 22.0, 1.05, 0),
      (_dark, 14.0, 1.0, 18),
      (_darkFloor, 18.0, 0.85, 12),
    ]) {
      final f = _Frame(480, 360, bg)..cam(240, 180, k);
      // 3x3 흐림
      final src = Uint8List.fromList(f.px);
      for (var y = 1; y < f.h - 1; y++) {
        for (var x = 1; x < f.w - 1; x++) {
          for (var c = 0; c < 3; c++) {
            var sum = 0;
            for (var dy = -1; dy <= 1; dy++) {
              for (var dx = -1; dx <= 1; dx++) {
                sum += src[((y + dy) * f.w + x + dx) * 4 + c];
              }
            }
            final v = sum / 9 * gain + lift + rnd.nextInt(17) - 8; // 노출 · 검은색 뜸 · 센서 노이즈
            f.px[(y * f.w + x) * 4 + c] = v.round().clamp(0, 255);
          }
        }
      }
      expect(_detect(f), isTrue, reason: 'bg=$bg k=$k gain=$gain lift=$lift');
    }
  });

  test('빈 화면 · 조준 영역 밖의 몰카는 무시', () {
    final f = _Frame(480, 360, _light);
    expect(_detect(f), isFalse);
    f.cam(30, 30, 12);
    expect(_detect(f), isFalse);
  });

  test('무작위 빨간 · 검은 · 파란 도형이 섞인 화면에서 오탐 없음', () {
    final rnd = Random(7);
    var falsePositive = 0;
    for (var trial = 0; trial < 60; trial++) {
      final f = _Frame(240, 180, trial.isEven ? _light : _darkFloor);
      for (var i = 0; i < 14; i++) {
        final x = rnd.nextDouble() * 240, y = rnd.nextDouble() * 180, s = 3 + rnd.nextDouble() * 18;
        switch (rnd.nextInt(4)) {
          case 0:
            f.circle(x, y, s, _red);
          case 1:
            f.rect(x, y, s * (0.5 + rnd.nextDouble() * 2), s, _body);
          case 2:
            f.circle(x, y, s * 0.5, _lens);
          default:
            f.circle(x, y, s * 2, [255, 40, 40], alpha: (t) => .8 * (1 - t));
        }
      }
      if (_detect(f)) falsePositive++;
    }
    expect(falsePositive, 0);
  });
}
