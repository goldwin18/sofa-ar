#!/usr/bin/env bash
# One-time setup. Needs Flutter installed (https://docs.flutter.dev/get-started/install).
# Creates the android/ folder, patches it for this app, and fetches packages.
set -euo pipefail
cd "$(dirname "$0")"

# `flutter create` must not overwrite our own files, so park them while it runs.
mkdir -p .keep && cp -r lib pubspec.yaml .keep/
flutter create --platforms=android --org com.sofaar --project-name sofa_ar .
rm -rf lib pubspec.yaml && cp -r .keep/lib .keep/pubspec.yaml . && rm -rf .keep

python3 tool/patch_android.py
flutter pub get

echo
echo "Done. Connect a phone and run:   flutter run"
echo "Or build the APK:                flutter build apk --release"
echo "APK appears at:                  build/app/outputs/flutter-apk/app-release.apk"
