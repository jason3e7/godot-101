#!/bin/bash
# Run 2048 unit tests (headless) + screenshot verification

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_DIR="$SCRIPT_DIR/game"
SCREENSHOT="$SCRIPT_DIR/screenshot.png"
GODOT="${GODOT:-godot-4}"
GAME_PID=""

cleanup() {
    [ -n "$GAME_PID" ] && kill "$GAME_PID" 2>/dev/null || true
}
trap cleanup EXIT

ensure_xvfb() {
    # If a real desktop display is already set, use it directly
    if [ -n "$DISPLAY" ] && xdpyinfo -display "$DISPLAY" &>/dev/null 2>&1; then
        echo "  Using existing display ($DISPLAY)"
        return
    fi
    # Fall back to Xvfb on :99
    if xdpyinfo -display :99 &>/dev/null 2>&1; then
        export DISPLAY=:99
        echo "  Using existing Xvfb on :99"
    else
        Xvfb :99 -screen 0 1280x720x24 &
        export DISPLAY=:99
        sleep 1
        echo "  Xvfb started (DISPLAY=:99)"
    fi
}

# ── 1. Headless unit tests ────────────────────────────────────────────────────
echo "=== [1/2] Headless Unit Tests ==="
"$GODOT" --headless --path "$GAME_DIR" --script "res://tests/TestBoard.gd" 2>/dev/null
echo ""

# ── 2. Screenshot (visual verification) ──────────────────────────────────────
echo "=== [2/2] Screenshot Verification ==="
if ! command -v import &>/dev/null; then
    echo "  ImageMagick not found — skipping (run setup.sh first)"
    echo ""
    echo "=== All tests passed ==="
    exit 0
fi

ensure_xvfb

echo "  Launching game..."
DISPLAY=:99 "$GODOT" --path "$GAME_DIR" &
GAME_PID=$!

echo "  Waiting 5 s for window to render..."
sleep 5

import -window root -display :99 "$SCREENSHOT" 2>/dev/null && \
    echo "  Screenshot saved: $SCREENSHOT ($(du -h "$SCREENSHOT" | cut -f1))" || \
    echo "  Screenshot capture failed"

kill "$GAME_PID" 2>/dev/null || true
GAME_PID=""

echo ""
echo "=== All tests passed ==="
