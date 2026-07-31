$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
Push-Location packages/veyra_lab; dart test; Pop-Location
Push-Location apps/veyra_observatory; flutter test; flutter build web --release; Pop-Location
dart run tool/verify_transformative_use.dart
