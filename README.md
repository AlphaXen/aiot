# AIoT

하나의 Flutter 프로젝트 안에 웹앱 두 개가 들어 있습니다.

| 앱 | 진입점 | 용도 | 배포 폴더 |
|---|---|---|---|
| **AIoT Home** | `lib/main_mobile.dart` | 스마트폰용 IoT 제어 웹앱 | `deploy/mobile` |
| **AIoT Console** | `lib/main_admin.dart` | PC용 관리자 대시보드 | `deploy/admin` |

## 구조

```
lib/
  shared/          두 앱이 같이 쓰는 모델과 상태 저장소 (HomeStore)
  mobile/          제어 앱: 즐겨찾기 · 기기 · 라이프 · 자동화 · 메뉴, 기기 상세 제어
  admin/           대시보드: 개요 · 기기 · 장소/방 · 자동화 · 멤버 · 활동 로그 · 펌웨어
  main_mobile.dart
  main_admin.dart
  main.dart        = 모바일 앱 (기본 실행용)
scripts/
  build_web.ps1    두 앱을 빌드해서 deploy/* 로 복사 (+ 선택적으로 Vercel 배포)
  vercel_build.sh  Git 연동 배포 시 Vercel 빌드 서버에서 실행
deploy/
  mobile/vercel.json
  admin/vercel.json
```

## 로컬 실행

```powershell
flutter run -d chrome -t lib/main_mobile.dart   # 모바일 앱 (F12 → 기기 모드로 보면 폰 화면)
flutter run -d chrome -t lib/main_admin.dart    # 관리자 대시보드
flutter test
```

## Vercel 배포 (프로젝트 2개)

### 방법 A — 로컬 빌드 후 업로드 (가장 간단)

```powershell
npm i -g vercel        # 처음 한 번
vercel login           # 처음 한 번

.\scripts\build_web.ps1                 # deploy/mobile, deploy/admin 생성
cd deploy\mobile; vercel --prod; cd ..\..   # 처음엔 새 프로젝트 이름 입력 (예: aiot-home)
cd deploy\admin;  vercel --prod; cd ..\..   # (예: aiot-console)
```

처음 한 번 연결하고 나면 `.\scripts\build_web.ps1 all -Deploy` 한 줄로 빌드와 배포가 같이 됩니다.

### 방법 B — GitHub 저장소 연동 (push하면 자동 배포)

같은 저장소를 Vercel에서 프로젝트 두 개로 import하고 각각 이렇게 설정합니다.

| 설정 | 모바일 프로젝트 | 관리자 프로젝트 |
|---|---|---|
| Framework Preset | Other | Other |
| Build Command | `bash scripts/vercel_build.sh mobile` | `bash scripts/vercel_build.sh admin` |
| Output Directory | `build/web_mobile` | `build/web_admin` |
| Install Command | `true` | `true` |

빌드할 때마다 Flutter SDK를 받기 때문에 첫 빌드는 몇 분 걸립니다.

## 데이터에 대해

지금은 `lib/shared/home_store.dart`의 **샘플 데이터**로 동작하고, 상태는 각 앱의 브라우저 메모리에만 있습니다.
즉 모바일에서 전등을 꺼도 관리자 대시보드에는 반영되지 않습니다. 실제 기기와 연결하려면
`HomeStore`의 메서드(`togglePower`, `setLevel` 등) 안에서 백엔드(MQTT 브로커, Firebase, Supabase, 자체 REST API 등)를
호출하도록 바꾸면 두 앱이 같은 데이터를 보게 됩니다.
