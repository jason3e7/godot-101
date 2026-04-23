# 2048 — Godot 4

A 2048 sliding-tile puzzle game built with Godot Engine 4.

## Prerequisites

| Tool | Purpose |
|------|---------|
| [snap](https://snapcraft.io/) | Godot 4 installation |
| Godot 4 (`godot-4`) | Game engine |
| Xvfb | Virtual framebuffer — headless / server testing |
| ImageMagick | Screenshot capture for visual verification |

## Setup

```bash
./setup.sh
```

Installs Godot 4 (snap), Xvfb, and ImageMagick on Ubuntu/Debian.

## Run the game

```bash
# With a desktop environment
godot-4 --path game/

# On a headless server (virtual display)
Xvfb :99 -screen 0 1280x720x24 &
DISPLAY=:99 godot-4 --path game/
```

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move tiles |
| New Game button | Restart |

## Run tests

### Full test suite (headless, no display required)

```bash
./test.sh
```

Two stages:
1. **Unit tests** — pure game logic via `godot-4 --headless --script`, no display needed
2. **Screenshot** — launches the game on Xvfb and captures `screenshot.png` as visual proof

### Watch tests run live (with a desktop)

If you are logged into a desktop session (local or remote), run the test script directly in a terminal — it will detect the existing `$DISPLAY` and skip Xvfb:

```bash
bash test.sh
```

Or run only the unit tests and watch the output scroll in real time:

```bash
godot-4 --path game/ --script "res://tests/TestBoard.gd"
```

Godot opens a window, runs all 13 assertions, prints PASS/FAIL to the terminal, then exits with code `0` (all pass) or `1` (any fail).

## Project structure

```
game/
├── project.godot          — Godot project config
├── scenes/
│   └── Main.tscn          — Root scene (Control node)
├── scripts/
│   ├── Board.gd           — Game logic (grid, moves, scoring, win/over)
│   └── Main.gd            — UI: tile rendering, input, score display
└── tests/
    └── TestBoard.gd       — Headless unit tests (extends SceneTree)
```

## Tested logic

- New game spawns exactly 2 tiles with score 0
- Slide left / right / up / down: tiles merge correctly
- No double-merge in a single move (`[2,2,2,2]` → `[4,4,0,0]`)
- Score accumulates from merges
- `game_won` signal fires when a 2048 tile is created
- `is_game_over()` returns true on a fully locked board
- `move()` returns false when no move is possible
