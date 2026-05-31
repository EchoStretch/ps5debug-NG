#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SDK_SRC="$SCRIPT_DIR/ps5-payload-sdk"
SDK_INSTALL="$SDK_SRC/install"
ARTIFACT="$SCRIPT_DIR/ps5debug-NG.elf"

clean_build() {
    echo "==> cleaning"
    (cd debugger  && make clean) || true
    (cd installer && make clean) || true
    (cd "$SDK_SRC" && make clean) || true
    rm -rf "$SDK_INSTALL" "$ARTIFACT"
}

build_sdk() {
    if [ ! -f "$SDK_INSTALL/toolchain/prospero.mk" ]; then
        echo "==> building SDK (one-time, ~30s)"
        mkdir -p "$SDK_INSTALL"
        make -C "$SDK_SRC" DESTDIR="$SDK_INSTALL" -j"$(nproc)" install
    else
        echo "==> SDK already built at $SDK_INSTALL"
    fi
}

build_debugger() {
    echo "==> building debugger"
    make -C debugger
}

build_installer() {
    echo "==> building installer (embeds debugger)"
    make -C installer
}

publish_artifact() {
    cp installer/build/ps5debug-NG.elf "$ARTIFACT"
    echo "==> ps5debug-NG.elf ready ($(stat -c %s "$ARTIFACT") bytes)"
}

if [ "${1:-}" = "clean" ]; then
    clean_build
    exit 0
fi

build_sdk
build_debugger
build_installer
publish_artifact
