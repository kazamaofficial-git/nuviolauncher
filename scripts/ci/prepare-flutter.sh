#!/usr/bin/env bash
# Prepares the Flutter project for a build: generates the platform folders on first use,
# applies Nuvio's platform patches, fetches packages and generates launcher icons.
#
# Usage: scripts/ci/prepare-flutter.sh <android|windows>
set -euo pipefail

# `python3` does not exist on Windows runners; fall back to `python`.
PY="$(command -v python3 || command -v python)"

platform="${1:?usage: prepare-flutter.sh <android|windows>}"
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root/app"

if [ ! -d "$platform" ]; then
  echo "::group::flutter create ($platform)"
  flutter create --platforms="$platform" --org com.kazamatech --project-name nuvio_launcher .
  # `flutter create` adds a default smoke test that references a sample app we do not have.
  rm -f test/widget_test.dart
  echo "::endgroup::"
fi

case "$platform" in
  android) "$PY" "$root/scripts/ci/configure_android.py" android/app/src/main/AndroidManifest.xml ;;
  windows) "$PY" "$root/scripts/ci/configure_windows.py" windows/runner/Runner.rc ;;
esac

flutter pub get
dart run flutter_launcher_icons
