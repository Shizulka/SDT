#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="$1"

echo "Checking service availability..."
curl -f "$TARGET_URL/"

echo "Checking docs..."
curl -f "$TARGET_URL/docs"

echo "Checking nginx headers..."
curl -I "$TARGET_URL/"

echo "Verification completed successfully"