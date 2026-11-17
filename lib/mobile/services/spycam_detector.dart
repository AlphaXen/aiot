import 'dart:typed_data';
import 'dart:ui' as ui;

/// 사진 한 장에서 찾은 몰카 후보. 좌표는 조준 영역(가운데 정사각형) 기준 0~1.
class SpyDetection {
  const SpyDetection({required this.found, this.x = 0.5, this.y = 0.5, this.size = 0, this.score = 0});
  static const none = SpyDetection(found: false);

  final bool found;
  final double x;
  final double y;

  /// 불빛 지름 (조준 영역 한 변 대비)
  final double size;
  final double score;
}

/// 조준 영역 = 사진 가운데의 정사각형 (짧은 변의 [kAimFraction] 배). 화면의 조준선과 같은 크기.
const kAimFraction = 0.62;

/// 사진(JPEG/PNG 바이트)을 브라우저/엔진 디코더로 줄여서 읽고 [detectHiddenCamera] 실행.
/// 사진의 가로/세로 비율도 함께 돌려줍니다 (미리보기 크기 맞추기용).
Future<(SpyDetection, double aspect)> detectInPhoto(Uint8List bytes, {int targetWidth = 480}) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
  final frame = await codec.getNextFrame();
  final img = frame.image;
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  final w = img.width, h = img.height;
  img.dispose();
  codec.dispose();
  if (data == null) return (SpyDetection.none, w / h);
  return (detectHiddenCamera(data.buffer.asUint8List(), w, h), w / h);
}

/// 몰카 판정: "켜진 빨간 LED(붉은 불빛 덩어리)" + "바로 옆의 검은 카메라 몸체".
///
/// 1. 조준 영역에서 밝고 채도 높은 빨간 픽셀(+ 과노출로 분홍빛이 된 LED 중심)을 찾는다.
/// 2. 8방향 연결 덩어리로 묶고, 너무 작거나 크거나 길쭉한 것(글자 배지 등)은 버린다.
/// 3. 덩어리 bbox 안(+2px)에 어두운 픽셀이 충분히 있어야 한다 → 빛 번짐 속의 카메라 몸체.
SpyDetection detectHiddenCamera(Uint8List rgba, int w, int h) {
  final side = (w < h ? w : h) * kAimFraction ~/ 1;
  if (side < 16) return SpyDetection.none;
  final x0 = (w - side) ~/ 2, y0 = (h - side) ~/ 2;
  final n = side * side;

  // 0 = 기타, 1 = 빨간 불빛, 2 = 어두움
  final cls = Uint8List(n);
  for (var y = 0; y < side; y++) {
    var p = ((y0 + y) * w + x0) * 4;
    final row = y * side;
    for (var x = 0; x < side; x++, p += 4) {
      final r = rgba[p], g = rgba[p + 1], b = rgba[p + 2];
      final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
      if (mx < 70) {
        cls[row + x] = 2;
        continue;
      }
      if (r != mx) continue;
      final mn = g < b ? g : b;
      final chroma = r - mn;
      final gbDiff = (g - b).abs();
      // 색상 ±25° 안쪽, 채도 0.45 이상, 밝기 0.55 이상
      final vivid = r >= 140 && chroma >= r * 0.45 && gbDiff <= chroma * 0.42;
      // 카메라 센서가 포화된 LED 중심: 거의 흰데 붉은 기
      final hot = r >= 235 && mn >= 120 && r - (g > b ? g : b) >= 28;
      if (vivid || hot) cls[row + x] = 1;
    }
  }

  final minArea = (n * 0.00012).clamp(5, 1e9);
  final maxArea = n * 0.12;
  final seen = Uint8List(n);
  final stack = <int>[];
  var best = SpyDetection.none;

  for (var start = 0; start < n; start++) {
    if (cls[start] != 1 || seen[start] == 1) continue;
    // 덩어리 하나 채우기
    var area = 0, minX = side, minY = side, maxX = 0, maxY = 0;
    var sumX = 0, sumY = 0;
    stack.add(start);
    seen[start] = 1;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final cx = i % side, cy = i ~/ side;
      area++;
      sumX += cx;
      sumY += cy;
      if (cx < minX) minX = cx;
      if (cx > maxX) maxX = cx;
      if (cy < minY) minY = cy;
      if (cy > maxY) maxY = cy;
      for (var dy = -1; dy <= 1; dy++) {
        final ny = cy + dy;
        if (ny < 0 || ny >= side) continue;
        for (var dx = -1; dx <= 1; dx++) {
          final nx = cx + dx;
          if (nx < 0 || nx >= side) continue;
          final j = ny * side + nx;
          if (cls[j] == 1 && seen[j] == 0) {
            seen[j] = 1;
            stack.add(j);
          }
        }
      }
    }

    if (area < minArea || area > maxArea) continue;
    final bw = maxX - minX + 1, bh = maxY - minY + 1;
    final aspect = bw > bh ? bw / bh : bh / bw;
    if (aspect > 3) continue; // 가로로 긴 경고 배지 · 글자 줄
    final fill = area / (bw * bh);
    if (fill < 0.28) continue;

    // 어두운 픽셀 비율 (카메라 몸체는 붉은 빛 번짐 안쪽 · 바로 옆에 있음)
    const pad = 2;
    final ex0 = (minX - pad).clamp(0, side - 1), ex1 = (maxX + pad).clamp(0, side - 1);
    final ey0 = (minY - pad).clamp(0, side - 1), ey1 = (maxY + pad).clamp(0, side - 1);
    var dark = 0, total = 0;
    for (var y = ey0; y <= ey1; y++) {
      for (var x = ex0; x <= ex1; x++) {
        total++;
        if (cls[y * side + x] == 2) dark++;
      }
    }
    final darkFrac = dark / total;
    if (dark < 4 || darkFrac < 0.035) continue;

    final score = fill.clamp(0, 1) * (darkFrac * 8).clamp(0, 1) * (1 - (aspect - 1) / 4);
    if (score > best.score) {
      best = SpyDetection(
        found: true,
        x: (sumX / area + 0.5) / side,
        y: (sumY / area + 0.5) / side,
        size: (bw > bh ? bw : bh) / side,
        score: score.toDouble(),
      );
    }
  }
  return best;
}
