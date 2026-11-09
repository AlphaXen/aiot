#!/usr/bin/env bash
# Git 연동 배포용: Vercel 빌드 서버에서 Flutter를 설치하고 웹앱 하나를 빌드합니다.
#
# Vercel 프로젝트 설정 (프로젝트 2개, 같은 저장소):
#   [모바일]  Build Command:   bash scripts/vercel_build.sh mobile
#             Output Directory: build/web_mobile
#   [관리자]  Build Command:   bash scripts/vercel_build.sh admin
#             Output Directory: build/web_admin
#   공통      Framework Preset: Other, Install Command: (비워두기 또는 `true`)
set -euo pipefail

TARGET="${1:?usage: vercel_build.sh <mobile|admin>}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.2}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter --version
flutter pub get
flutter build web -t "lib/main_${TARGET}.dart" -o "build/web_${TARGET}" --release

if [ "$TARGET" = "admin" ]; then TITLE="캠퍼스 식당 관리자"; else TITLE="캠퍼스 식당"; fi
sed -i "s|<title>AIoT</title>|<title>${TITLE}</title>|" "build/web_${TARGET}/index.html"
