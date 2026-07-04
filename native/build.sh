#!/usr/bin/env sh
# Builds the vendored Box2D C library into a static archive that dub links.
# Invoked by dub via preBuildCommands. Safe to run repeatedly (incremental).
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$DIR/box2d"
BUILD="$SRC/build"
OUT="$DIR/libbox2d.a"

if ! command -v cmake >/dev/null 2>&1; then
    echo "box2d.d: cmake is required to build the vendored Box2D library." >&2
    echo "         Install cmake, or use the \"system\" configuration to link a system Box2D." >&2
    exit 1
fi

cmake -S "$SRC" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$BUILD" --config Release -j >/dev/null

# Copy to a stable path regardless of single/multi-config generator layout.
LIB="$(find "$BUILD" -name libbox2d.a -print 2>/dev/null | head -n 1)"
if [ -z "$LIB" ]; then
    echo "box2d.d: failed to locate built libbox2d.a under $BUILD" >&2
    exit 1
fi
cp "$LIB" "$OUT"
