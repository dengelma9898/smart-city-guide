#!/bin/bash
set -euo pipefail
echo "[CI] Post-clone: configuring Git and Xcode"
git config --global --add safe.directory /Volumes/workspace/repository || true
echo "[CI] Xcode version: $(xcodebuild -version | tr '\n' ' ')"

