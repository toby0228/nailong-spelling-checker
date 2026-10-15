#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -x build/Nailong.app/Contents/MacOS/Nailong ]]; then ./build.sh; fi
# The app now includes a graphical browser installer: no Terminal choices or Python.
open build/Nailong.app
printf 'In Nailong click “Connect / repair browser…” to finish.\n'
