#!/bin/bash
set -euo pipefail
echo "[CI] Pre-xcodebuild: disabling signing for CI builds"
export CODE_SIGNING_ALLOWED=NO
export COMPILER_INDEX_STORE_ENABLE=NO
echo "[CI] Environment prepared"

