#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "用法: ./bump-version.sh <版本号>"
  echo "示例: ./bump-version.sh 0.4.0"
  exit 1
fi

VERSION="$1"

if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
  echo "错误: 版本号格式不正确，应为 x.y.z 或 x.y.z-tag"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
PKG="$ROOT/package.json"
CONF="$ROOT/src-tauri/tauri.conf.json"

OLD_VER=$(jq -r '.version' "$PKG")
if [ "$OLD_VER" = "$VERSION" ]; then
  echo "版本号未变化 ($VERSION)"
  exit 0
fi

jq --arg v "$VERSION" '.version = $v' "$PKG" > "$PKG.tmp" && mv "$PKG.tmp" "$PKG"
jq --arg v "$VERSION" '.version = $v' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"

echo "版本号: $OLD_VER -> $VERSION"
echo "  已更新 package.json"
echo "  已更新 src-tauri/tauri.conf.json"
