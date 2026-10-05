#!/bin/bash
set -euo pipefail
PET_PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
PET_VERSION="${1:-1.0.0}"
if [[ ! "$PET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'Version must use MAJOR.MINOR.PATCH.' >&2
  exit 1
fi
cd "$PET_PROJECT"
mkdir -p dist
PET_STAGING="$(mktemp -d "$PET_PROJECT/dist/staging.XXXXXX")"
trap 'rm -rf "$PET_STAGING"' EXIT
for PET_ARCH in x86_64 arm64; do
  swift build --disable-sandbox -c release -j 2 --triple "$PET_ARCH-apple-macosx11.0" --scratch-path ".build/$PET_ARCH"
done
PET_INTEL="$(swift build --disable-sandbox -c release --triple x86_64-apple-macosx11.0 --scratch-path .build/x86_64 --show-bin-path)"
PET_ARM="$(swift build --disable-sandbox -c release --triple arm64-apple-macosx11.0 --scratch-path .build/arm64 --show-bin-path)"
PET_APP="$PET_STAGING/Pati Cepte.app"
mkdir -p "$PET_APP/Contents/MacOS" "$PET_APP/Contents/Resources"
lipo -create "$PET_INTEL/TouchBarPet" "$PET_ARM/TouchBarPet" -output "$PET_APP/Contents/MacOS/TouchBarPet"
cp Resources/Info.plist "$PET_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $PET_VERSION" "$PET_APP/Contents/Info.plist"
cp LICENSE "$PET_APP/Contents/Resources/LICENSE.txt"
"$PET_INTEL/TouchBarPet" --iconset "$PET_STAGING/AppIcon.iconset"
iconutil -c icns "$PET_STAGING/AppIcon.iconset" -o "$PET_APP/Contents/Resources/AppIcon.icns"
rm -rf "$PET_STAGING/AppIcon.iconset"
codesign --force --sign - --timestamp=none "$PET_APP"
codesign --verify --strict "$PET_APP"
lipo "$PET_APP/Contents/MacOS/TouchBarPet" -verify_arch x86_64 arm64
"$PET_APP/Contents/MacOS/TouchBarPet" --smoke-test
cp README.md README.tr.md LICENSE CHANGELOG.md "$PET_STAGING/"
cp -R docs "$PET_STAGING/docs"
PET_ZIP="TouchBarPet-v$PET_VERSION-universal.zip"
rm -f "dist/$PET_ZIP"
python3 scripts/archive.py "$PET_STAGING" "dist/$PET_ZIP"
(cd dist && shasum -a 256 "$PET_ZIP" > SHA256SUMS.txt)
echo "Packaged: $PET_PROJECT/dist/$PET_ZIP"
lipo -archs "$PET_APP/Contents/MacOS/TouchBarPet"
