# 2048 — Godot 4

A 2048 sliding-tile puzzle game built with Godot Engine 4.

## Prerequisites

| Tool | Purpose |
|------|---------|
| [snap](https://snapcraft.io/) | Godot 4 installation |
| Godot 4 (`godot-4`) | Game engine |
| Xvfb | Virtual framebuffer — headless / server testing |
| scrot | Screenshot capture for visual verification |

## Setup

```bash
./setup.sh
```

Installs Godot 4 (snap), Xvfb, and scrot on Ubuntu/Debian.

## Run the game

```bash
# Locally (with display)
godot-4 --path game/

# On a server (virtual display)
Xvfb :99 -screen 0 1280x720x24 &
DISPLAY=:99 godot-4 --path game/
```

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move tiles |
| New Game button | Restart |

## Run tests

```bash
./test.sh
```

Two stages:
1. **Headless unit tests** — pure game logic, no display required
2. **Screenshot** — launches the game briefly and captures a screenshot as `screenshot.png`

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
