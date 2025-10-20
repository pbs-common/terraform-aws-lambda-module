#!/usr/bin/env bash

# Unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

GIT_ROOT=$(git rev-parse --show-toplevel)
ARTIFACTS_DIR="$GIT_ROOT/examples/artifacts"
SRC_DIR="$GIT_ROOT/examples/src"
SRC_APP_CONFIG_DIR="$GIT_ROOT/examples/src-app-config"

mkdir -p "$ARTIFACTS_DIR"

# Build x86_64
echo "🔨 Building x86_64 Lambda binary for provided.al2023..."
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "$ARTIFACTS_DIR/bootstrap" "$SRC_DIR/main.go"
zip -j "$ARTIFACTS_DIR/handler.zip" "$ARTIFACTS_DIR/bootstrap"

# Build ARM64
echo "🔨 Building ARM64 Lambda binary for provided.al2023..."
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o "$ARTIFACTS_DIR/bootstrap" "$SRC_DIR/main.go"
zip -j "$ARTIFACTS_DIR/arm-handler.zip" "$ARTIFACTS_DIR/bootstrap"

# Package Python app config Lambda
echo "📦 Packaging Python app config Lambda..."
zip -j "$ARTIFACTS_DIR/app-config-handler.zip" "$SRC_APP_CONFIG_DIR/main.py"

echo "✅ Lambda artifacts ready in $ARTIFACTS_DIR"
