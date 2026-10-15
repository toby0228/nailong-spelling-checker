#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -x build/Nailong.app/Contents/MacOS/Nailong ]]; then ./build.sh; fi
open build/Nailong.app
