import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/spycam_detector.dart';
import '../../shared/aiot_server.dart';

/// 카메라로 몰래카메라를 찍어서 인식되면 서버에 '수거'를 보고 → 시뮬레이터에서 귀신이 잡힙니다.
///
/// 미리보기 중에는 0.3초마다 한 장씩 분석해 조준선 안의 몰카(검은 몸체 + 렌즈 + 켜진 LED)를 표시하고,
/// 촬영 버튼을 누르면 0.2초 간격으로 최대 4장을 찍어 판정합니다 (LED가 깜박여서 한 장이면 놓칠 수 있음).
class SpycamScanScreen extends StatefulWidget {
  const SpycamScanScreen({super.key, this.roomId});
  final String? roomId;

  @override
  State<SpycamScanScreen> createState() => _SpycamScanScreenState();
}

class _SpycamScanScreenState extends State<SpycamScanScreen> {
  static const _danger = Color(0xFFEF4444);

  final _svc = AiotServer.instance;
  CameraController? _cam;
  String? _error;
  String? _roomId;
  double? _aspect;
  SpyDetection _live = SpyDetection.none;
  bool _shootRequested = false;
  bool _shooting = false;
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId ?? (_svc.planted.isEmpty ? null : _svc.planted.first.id);
    _svc.addListener(_onService);
    _svc.refresh();
    _init();
  }

  @override
  void dispose() {
    _alive = false;
    _svc.removeListener(_onService);
    _cam?.dispose();
    super.dispose();
  }

  void _onService() {
    if (!mounted) return;
    // 선택한 식당의 몰카가 사라졌고 다른 곳에 있으면 그쪽으로
    final cur = _roomId == null ? null : _svc.byId(_roomId!);
    if ((cur == null || !cur.planted) && _svc.planted.isNotEmpty) _roomId = _svc.planted.first.id;
    setState(() {});
  }

  /// 웹: availableCameras()가 getUserMedia로 브라우저 권한 팝업을 띄웁니다.
  /// 거부하면 CameraException('CameraAccessDenied') (camera_web CameraErrorCode).
  Future<void> _init() async {
    if (_error != null) setState(() => _error = null);
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw CameraException('cameraNotFound', '카메라가 없습니다');
      final cam = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final ctl = CameraController(cam, ResolutionPreset.high, enableAudio: false);
      await ctl.initialize();
      if (!_alive) {
        ctl.dispose();
        return;
      }
      setState(() => _cam = ctl);
      _loop();
    } on CameraException catch (e) {
      debugPrint('camera init failed: ${e.code} ${e.description}');
      if (_alive) setState(() => _error = cameraErrorMessage(e.code));
    } catch (e) {
      debugPrint('camera init failed: $e');
      if (_alive) setState(() => _error = cameraErrorMessage('$e'));
    }
  }

  Future<(Uint8List?, SpyDetection)> _grab() async {
    try {
      final file = await _cam!.takePicture();
      final bytes = await file.readAsBytes();
      final (det, aspect) = await detectInPhoto(bytes);
      _aspect ??= aspect;
      return (bytes, det);
    } catch (e) {
      debugPrint('grab failed: $e');
      return (null, SpyDetection.none);
    }
  }

  /// 카메라 접근은 이 루프 하나에서만 (takePicture 동시 호출 방지)
  Future<void> _loop() async {
    while (_alive && _cam != null) {
      if (_shootRequested) {
        _shootRequested = false;
        await _shoot();
        continue;
      }
      final (_, det) = await _grab();
      if (!_alive) return;
      setState(() => _live = det);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  void _requestShoot() {
    if (_shooting || _cam == null) return;
    setState(() {
      _shooting = true;
      _shootRequested = true;
    });
  }

  Future<void> _shoot() async {
    Uint8List? photo;
    var det = SpyDetection.none;
    for (var i = 0; i < 4 && _alive; i++) {
      final (b, d) = await _grab();
      photo ??= b;
      if (d.found) {
        photo = b;
        det = d;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (!_alive) return;
    setState(() => _live = det);

    if (!det.found) {
      setState(() => _shooting = false);
      _snack('몰카를 인식하지 못했어요. 검은 몸체 · 렌즈 · 빨간 LED가 모두 조준선 안에 또렷이 보이게 다가가서 다시 찍어 보세요.');
      return;
    }

    final room = _roomId == null ? null : _svc.byId(_roomId!);
    RemoveResult? result;
    if (room != null && room.planted) result = await _svc.removeCamera(room);
    if (!_alive || !mounted) return;
    setState(() => _shooting = false);

    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ResultSheet(photo: photo, det: det, room: room, result: result),
    );
    if (done == true && mounted) Navigator.of(context).pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('몰카 촬영 탐지', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Column(
        children: [
          _RoomPicker(rooms: _svc.rooms, selected: _roomId, onSelect: (id) => setState(() => _roomId = id)),
          Expanded(child: Center(child: _preview())),
          _bottom(),
        ],
      ),
    );
  }

  Widget _preview() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 48),
            const SizedBox(height: 14),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.5)),
            const SizedBox(height: 18),
            // 권한 팝업을 그냥 닫은 경우(차단 아님)엔 다시 물어봅니다
            OutlinedButton.icon(
              onPressed: _init,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    final cam = _cam;
    if (cam == null) return const CircularProgressIndicator(color: Colors.white);

    // 웹은 실제 찍힌 사진 비율로 미리보기 크기를 맞춤 (조준선 = 분석 영역)
    final Widget view = kIsWeb
        ? AspectRatio(aspectRatio: _aspect ?? cam.value.aspectRatio, child: cam.buildPreview())
        : CameraPreview(cam);
    return Stack(
      alignment: Alignment.center,
      children: [
        view,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              final side = c.biggest.shortestSide * kAimFraction;
              return Center(
                child: SizedBox.square(
                  dimension: side,
                  child: CustomPaint(painter: _AimPainter(det: _live, color: _live.found ? _danger : Colors.white)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bottom() {
    final found = _live.found;
    final room = _roomId == null ? null : _svc.byId(_roomId!);
    final String hint;
    if (_cam == null) {
      hint = _error == null ? '카메라를 여는 중…' : '';
    } else if (_shooting) {
      hint = '분석 중…';
    } else if (found) {
      hint = '몰카 포착! 지금 촬영하세요';
    } else if (room == null || !room.planted) {
      hint = '신고된 몰카가 없어요 · 연습 모드로 탐지만 해요';
    } else {
      hint = '${room.name} 책상 밑 몰카(빨간 LED가 켜진 검은 카메라)를 조준선 안에 담으세요';
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          children: [
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: found ? _danger : Colors.white70, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: '촬영해서 몰카 판정',
              child: GestureDetector(
                onTap: _requestShoot,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: found ? _danger : Colors.white, width: 4),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: found ? _danger : Colors.white),
                    child: _shooting
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black54),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 조준선 모서리 + 찾은 몰카 위치 원
class _AimPainter extends CustomPainter {
  _AimPainter({required this.det, required this.color});
  final SpyDetection det;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final l = s.width * 0.16;
    for (final (o, dx, dy) in [
      (Offset.zero, 1.0, 1.0),
      (Offset(s.width, 0), -1.0, 1.0),
      (Offset(0, s.height), 1.0, -1.0),
      (Offset(s.width, s.height), -1.0, -1.0),
    ]) {
      canvas.drawLine(o, o + Offset(l * dx, 0), p);
      canvas.drawLine(o, o + Offset(0, l * dy), p);
    }
    if (det.found) {
      final c = Offset(det.x * s.width, det.y * s.height);
      final r = (det.size * s.width * 0.8).clamp(14.0, s.width * 0.3);
      canvas.drawCircle(c, r, p..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(_AimPainter old) => old.det != det || old.color != color;
}

class _RoomPicker extends StatelessWidget {
  const _RoomPicker({required this.rooms, required this.selected, required this.onSelect});
  final List<SpyRoom> rooms;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          for (final r in rooms)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: r.id == selected,
                onSelected: (_) => onSelect(r.id),
                showCheckmark: false,
                backgroundColor: Colors.white10,
                selectedColor: Colors.white,
                side: BorderSide.none,
                avatar: r.planted ? const Icon(Icons.fiber_manual_record, size: 12, color: Color(0xFFEF4444)) : null,
                label: Text(
                  r.name,
                  style: TextStyle(
                    color: r.id == selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.photo, required this.det, required this.room, required this.result});
  final Uint8List? photo;
  final SpyDetection det;
  final SpyRoom? room;
  final RemoveResult? result;

  @override
  Widget build(BuildContext context) {
    final caught = result == RemoveResult.caught;
    final (IconData icon, Color color, String title, String body) = switch (result) {
      RemoveResult.caught => (
        Icons.verified_rounded,
        const Color(0xFF22C55E),
        '귀신 검거!',
        '${room!.name}의 몰래카메라를 찾아 수거했어요.\n센서룸 화면에서 귀신이 잡히는 걸 확인해 보세요.',
      ),
      RemoveResult.alreadyGone => (
        Icons.info_rounded,
        const Color(0xFF3E91FF),
        '이미 수거된 몰카예요',
        '다른 사람이 먼저 ${room!.name}의 몰카를 찾았어요.',
      ),
      RemoveResult.failed => (
        Icons.cloud_off_rounded,
        const Color(0xFFF59E0B),
        '몰카는 찾았지만 보고하지 못했어요',
        '서버에 연결하지 못했어요. 네트워크를 확인하고 다시 찍어 주세요.',
      ),
      null => (
        Icons.search_rounded,
        const Color(0xFFF59E0B),
        '몰카를 찾았어요',
        room == null
            ? '현재 몰카가 설치된 식당이 없어요. 센서룸에서 \'귀신 출몰\'을 누른 뒤 다시 해 보세요.'
            : '${room!.name}에는 신고된 몰카가 없어요. 위에서 식당을 바꿔 보세요.',
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Image.memory(photo!, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
            const SizedBox(height: 18),
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(caught || result == RemoveResult.alreadyGone),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(caught ? '완료' : '확인', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

/// camera_web 오류 코드(CameraErrorCode · DOMException.name) → 안내 문구
String cameraErrorMessage(String code) {
  final c = code.toLowerCase();
  if (c.contains('denied') || c.contains('notallowed') || c.contains('permission')) {
    return '카메라 권한이 거부되었어요.\n'
        '주소창 왼쪽 자물쇠(ⓘ) → 카메라 → 허용으로 바꾼 뒤 다시 시도해 주세요.\n'
        '(iPhone: 설정 → Safari → 카메라 → 허용)';
  }
  if (c.contains('notfound') || c.contains('devicesnotfound')) {
    return '사용할 수 있는 카메라를 찾지 못했어요.';
  }
  if (c.contains('notreadable') || c.contains('trackstart') || c.contains('abort')) {
    return '다른 앱이나 탭이 카메라를 쓰고 있어요.\n그 앱을 닫고 다시 시도해 주세요.';
  }
  if (c.contains('security') || c.contains('notsupported') || c.contains('type')) {
    return '이 브라우저에서는 카메라를 쓸 수 없어요.\nHTTPS 주소(https://aiot-home.vercel.app)에서 '
        'Chrome · Safari로 열어 주세요.\n(카카오톡 등 앱 안 브라우저라면 \'다른 브라우저로 열기\')';
  }
  return '카메라를 열 수 없어요 ($code).';
}
