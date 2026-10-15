#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if ! xcrun --find swift >/dev/null 2>&1; then
  echo "Nailong needs Apple's free Xcode Command Line Tools to build from source."
  echo "Starting the macOS installer. When it finishes, run 'bash Run.command' again."
  xcode-select --install
  exit 1
fi

if [[ ! -x build/Nailong.app/Contents/MacOS/Nailong ]]; then
  echo "Building Nailong from the checked-out source..."
  ./build.sh
fi

echo "Opening Nailong..."
open build/Nailong.app
