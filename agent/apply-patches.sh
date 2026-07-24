#!/bin/sh
# Apply frida-java-bridge patches for Android 16 compatibility.
# Run this after `npm install` from the agent/ directory.
set -e

DIR=node_modules/frida-java-bridge

if [ ! -d "$DIR" ]; then
  echo "Error: $DIR not found. Run 'npm install' first."
  exit 1
fi

PATCHES="patches/01-android-stripped-libart.patch patches/02-class-factory-transition-ref.patch"

for p in $PATCHES; do
  echo "Applying $p..."
  (cd "$DIR" && patch -p1 < "../../$p")
done

echo "All patches applied. Recompile with: npm run build"
