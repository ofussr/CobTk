#!/usr/bin/env bash

set -euo pipefail

# GnuCOBOL's MSYS2 helper currently misbehaves under strict shell mode,
# so set the three paths CobTk needs directly.
export COB_CONFIG_DIR="$(cygpath -w "$MINGW_PREFIX/share/gnucobol/config")"
export COB_COPY_DIR="$(cygpath -w "$MINGW_PREFIX/share/gnucobol/copy")"
export COB_LIBRARY_PATH="$(cygpath -w "$MINGW_PREFIX/lib/gnucobol")"

mkdir -p build

echo "[1/3] Building CobTk C bridge..."

gcc \
    -Wall \
    -Wextra \
    -O2 \
    -c src/cobtk.c \
    -o build/cobtk.o \
    $(pkg-config --cflags tk)

echo "[2/3] Building minimal demo..."

cobc \
    -x \
    -free \
    -I copybooks \
    examples/demo.cob \
    src/cobtk-api.cob \
    build/cobtk.o \
    $(pkg-config --libs tk) \
    -o build/demo.exe

echo "[3/3] Building widget demo..."

cobc \
    -x \
    -free \
    -I copybooks \
    examples/widgets.cob \
    src/cobtk-api.cob \
    build/cobtk.o \
    $(pkg-config --libs tk) \
    -o build/widgets.exe

echo
echo "Built successfully:"
echo "  build/demo.exe"
echo "  build/widgets.exe"
