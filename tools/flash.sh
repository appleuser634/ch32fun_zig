#!/usr/bin/env sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: tools/flash.sh <example>" >&2
  exit 2
fi

EXAMPLE="$1"
BIN="zig-out/firmware/${EXAMPLE}.bin"
MINICHLINK="../ch32fun/minichlink/minichlink"

if [ ! -x "$MINICHLINK" ]; then
  echo "minichlink not found: $MINICHLINK" >&2
  echo "Build it first: make -C ../ch32fun/minichlink" >&2
  exit 1
fi

if [ ! -f "$BIN" ]; then
  echo "missing binary: $BIN" >&2
  echo "run: zig build -Dexample=$EXAMPLE" >&2
  exit 1
fi

exec "$MINICHLINK" -w "$BIN" flash -b
