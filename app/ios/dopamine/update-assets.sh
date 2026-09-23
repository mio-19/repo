#!/usr/bin/env bash
set -e

# This script must be run on a macOS host (outside the Nix build sandbox)
# to generate the Assets.car file using Apple's official actool.
# Apple's actool relies on CoreSimulatorService, which crashes inside the nixbld daemon.

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Fetching Dopamine 3.0.9..."
git clone --depth 1 --branch 3.0.9 https://github.com/opa334/Dopamine.git "$TMPDIR/Dopamine"

echo "Compiling Assets.car..."
mkdir -p "$TMPDIR/output"
xcrun actool --compile "$TMPDIR/output" \
    --platform iphoneos \
    --minimum-deployment-target 15.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$TMPDIR/output/Info.plist" \
    "$TMPDIR/Dopamine/Application/Dopamine/Assets.xcassets"

echo "Copying Assets.car..."
cp "$TMPDIR/output/Assets.car" "$(dirname "$0")/Assets.car"

echo "Success! Assets.car updated."
