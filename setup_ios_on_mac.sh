#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Running flutter pub get..."
flutter pub get

echo "Installing CocoaPods dependencies..."
cd ios
pod install

echo "Opening Runner.xcworkspace..."
open Runner.xcworkspace
