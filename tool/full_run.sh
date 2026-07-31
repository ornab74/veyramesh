#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
(cd packages/veyra_lab && dart test)
(cd apps/veyra_observatory && flutter test)
(cd apps/veyra_observatory && flutter build web --release)
dart run tool/verify_transformative_use.dart
