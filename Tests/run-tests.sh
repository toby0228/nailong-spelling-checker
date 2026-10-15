#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./build.sh
./build/Nailong.app/Contents/MacOS/Nailong --self-test
python3 Tests/native_bridge_test.py
if command -v node >/dev/null 2>&1; then
  node Tests/browser.test.cjs
  node Tests/docs.test.cjs
else
  printf 'Browser checks skipped: install Node and run npm install --no-save playwright. Native tests passed.\n'
  exit 1
fi
