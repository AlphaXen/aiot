import 'package:aiot/mobile/screens/spycam_scan_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// camera_web 0.3.x가 실제로 던지는 CameraException 코드별 안내 문구
void main() {
  test('권한 거부 (CameraErrorCode.permissionDenied)', () {
    expect(cameraErrorMessage('CameraAccessDenied'), contains('권한이 거부'));
    expect(cameraErrorMessage('NotAllowedError'), contains('권한이 거부'));
  });
  test('카메라 없음 / 사용 중 / 지원 안 됨', () {
    expect(cameraErrorMessage('cameraNotFound'), contains('찾지 못했어요'));
    expect(cameraErrorMessage('cameraNotReadable'), contains('쓰고 있어요'));
    expect(cameraErrorMessage('cameraSecurity'), contains('HTTPS'));
    expect(cameraErrorMessage('cameraNotSupported'), contains('HTTPS'));
  });
  test('알 수 없는 코드는 코드를 그대로 보여줌', () {
    expect(cameraErrorMessage('cameraUnknown'), contains('cameraUnknown'));
  });
}
