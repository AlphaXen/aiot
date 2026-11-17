import 'dart:typed_data';
import 'dart:ui' as ui;

/// 사진 한 장에서 찾은 몰카. 좌표는 조준 영역(가운데 정사각형) 기준 0~1.
class SpyDetection {
  const SpyDetection({required this.found, this.x = 0.5, this.y = 0.5, this.size = 0, this.score = 0});
  static const none = SpyDetection(found: false);

  final bool found;

  /// 카메라 몸체 중심
  final double x;
  final double y;

  /// 카메라 몸체 가로 길이 (조준 영역 한 변 대비)
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

// 픽셀 분류
const _red = 1, _dark = 2, _blue = 3; // 0 = 기타

/// 몰카 판정. 센서룸 테스터의 몰카(web/index.html drawCam)와 같은 구조가 **모두** 보여야 인정합니다.
///
/// ```
///   ░░░░ 붉은 불빛 번짐 ░░░░        k = 크기 단위
///   ░┌──────────────●─┐░        몸체: 검은 직사각형 1.3k × 0.8k (가로:세로 ≈ 1.6)
///   ░│     ◯          │░        렌즈: 몸체 왼쪽 가운데의 푸른 회색 원 (가로 42% 지점)
///   ░└────────────────┘░        LED : 몸체 오른쪽 위의 빨간 점 (가로 82%, 세로 25% 지점)
///   ░░░░░░░░░░░░░░░░░░░░
/// ```
/// 1. 어두운 픽셀 덩어리 중 가로로 긴 꽉 찬 직사각형 → 몸체 후보
/// 2. 몸체 안 왼쪽 가운데에 푸른 렌즈
/// 3. 몸체 안 오른쪽 위에 켜진 빨간 LED (꺼진 LED · 렌즈보다 왼쪽이면 탈락)
/// 4. 몸체 바깥 테두리가 붉은 불빛으로 둘러싸여 있음
/// 빨간 물건 · 빨간 배지 · 검은 화면만으로는 통과할 수 없습니다.
SpyDetection detectHiddenCamera(Uint8List rgba, int w, int h) {
  final side = (w < h ? w : h) * kAimFraction ~/ 1;
  if (side < 24) return SpyDetection.none;
  final x0 = (w - side) ~/ 2, y0 = (h - side) ~/ 2;
  final n = side * side;

  final cls = Uint8List(n);
  // 불빛 번짐 확인용: 붉은 기가 도는 픽셀 (번짐은 바깥으로 갈수록 옅어져서 LED보다 느슨하게)
  final reddish = Uint8List(n);
  for (var y = 0; y < side; y++) {
    var p = ((y0 + y) * w + x0) * 4;
    final row = y * side;
    for (var x = 0; x < side; x++, p += 4) {
      final r = rgba[p], g = rgba[p + 1], b = rgba[p + 2];
      final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final i = row + x;
      if (r >= 100 && r - g >= 35 && r - b >= 35) reddish[i] = 1;
      if (mx < 75) {
        cls[i] = _dark;
      } else if (r == mx) {
        final chroma = r - mn;
        final vivid = r >= 170 && chroma >= r * 0.55 && (g - b).abs() <= chroma * 0.4;
        final hot = r >= 235 && mn >= 120 && r - (g > b ? g : b) >= 28; // 과노출된 LED 중심
        if (vivid || hot) cls[i] = _red;
      } else if (b == mx && b - r >= 15 && b - g >= 5) {
        cls[i] = _blue;
      }
    }
  }

  final seen = Uint8List(n);
  final stack = <int>[];
  final minArea = (n * 0.0004).clamp(40, 1e9);
  final maxArea = n * 0.3;
  var best = SpyDetection.none;

  for (var start = 0; start < n; start++) {
    if (cls[start] != _dark || seen[start] == 1) continue;
    var area = 0, minX = side, minY = side, maxX = 0, maxY = 0;
    stack.add(start);
    seen[start] = 1;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final cx = i % side, cy = i ~/ side;
      area++;
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
          if (cls[j] == _dark && seen[j] == 0) {
            seen[j] = 1;
            stack.add(j);
          }
        }
      }
    }

    // 1. 몸체: 가로로 긴 꽉 찬 직사각형 (렌즈 · LED 구멍 때문에 꽉 차진 않음)
    if (area < minArea || area > maxArea) continue;
    if (minX == 0 || minY == 0 || maxX == side - 1 || maxY == side - 1) continue; // 조준 영역에 잘린 덩어리
    final bw = maxX - minX + 1, bh = maxY - minY + 1;
    if (bh < 6) continue;
    final aspect = bw / bh;
    if (aspect < 1.2 || aspect > 2.3) continue;
    final boxArea = bw * bh;
    final fill = area / boxArea;
    if (fill < 0.4) continue; // 사진에선 몸체 가장자리가 번져 덜 차 보임

    // 2·3. 몸체 안의 렌즈(푸른색)와 LED(빨간색) 위치
    var blue = 0, bSumX = 0, bSumY = 0, red = 0, rSumX = 0, rSumY = 0;
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final c = cls[y * side + x];
        if (c == _blue) {
          blue++;
          bSumX += x;
          bSumY += y;
        } else if (c == _red) {
          red++;
          rSumX += x;
          rSumY += y;
        }
      }
    }
    if (blue < 3 || blue < boxArea * 0.03) continue;
    final lensX = (bSumX / blue - minX + 0.5) / bw, lensY = (bSumY / blue - minY + 0.5) / bh;
    if (lensX < 0.2 || lensX > 0.65 || lensY < 0.25 || lensY > 0.75) continue;

    if (red < 2 || red > boxArea * 0.25) continue;
    final ledX = (rSumX / red - minX + 0.5) / bw, ledY = (rSumY / red - minY + 0.5) / bh;
    if (ledX < 0.6 || ledY > 0.55 || ledX <= lensX) continue;

    // 4. 몸체를 둘러싼 붉은 불빛 (테두리 고리)
    final pad = (bh * 0.6).ceil().clamp(2, 1 << 20);
    final ex0 = minX - pad, ex1 = maxX + pad, ey0 = minY - pad, ey1 = maxY + pad;
    var ring = 0, ringRed = 0;
    for (var y = ey0; y <= ey1; y++) {
      if (y < 0 || y >= side) continue;
      for (var x = ex0; x <= ex1; x++) {
        if (x < 0 || x >= side) continue;
        if (x >= minX && x <= maxX && y >= minY && y <= maxY) continue;
        ring++;
        if (reddish[y * side + x] == 1) ringRed++;
      }
    }
    if (ring == 0) continue;
    final glow = ringRed / ring;
    if (glow < 0.35) continue;

    final shape = 1 - ((aspect - 1.625).abs() / 1.0).clamp(0.0, 0.6);
    final placement = 1 - ((lensX - 0.42).abs() + (ledX - 0.82).abs() + (ledY - 0.25).abs()).clamp(0.0, 0.6);
    final score = shape * placement * glow.clamp(0.0, 1.0) * fill.clamp(0.0, 1.0);
    if (score > best.score) {
      best = SpyDetection(
        found: true,
        x: (minX + bw / 2) / side,
        y: (minY + bh / 2) / side,
        size: bw / side,
        score: score,
      );
    }
  }
  return best;
}
