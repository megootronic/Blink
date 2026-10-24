#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
TEST_BUILD="$(mktemp -d "${TMPDIR:-/tmp}/blink-relaunched-server-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD"' EXIT

xcrun swiftc -swift-version 5 -O -module-cache-path "$TEST_BUILD/module-cache" \
    "$ROOT/Blink/Services/RelaunchedServer.swift" \
    "$ROOT/Tests/RelaunchedServerTests.swift" \
    -o "$TEST_BUILD/relaunched-server-tests"

"$TEST_BUILD/relaunched-server-tests"
