#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# This source-build launcher is intended to be invoked from Terminal:
#   bash Run.command
exec /bin/bash ./Start-Nailong.command "$@"
