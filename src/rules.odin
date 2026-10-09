package main

import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
TARGET_FPS :: 60

PLAYER_SPEED :: 220.0
PLAYER_RADIUS :: 13.0
INTERACTION_DISTANCE :: 58.0

COLOR_BACKGROUND :: rl.Color{17, 16, 35, 255}
COLOR_WALL       :: rl.Color{49, 42, 73, 255}
COLOR_FLOOR      :: rl.Color{31, 29, 54, 255}
COLOR_ACCENT     :: rl.Color{117, 220, 255, 255}
COLOR_GOLD       :: rl.Color{255, 211, 112, 255}
COLOR_TEXT       :: rl.Color{241, 238, 255, 255}
COLOR_MUTED      :: rl.Color{172, 169, 200, 255}
COLOR_LOCKED     :: rl.Color{110, 105, 130, 255}

SCREEN_TITLE :: "THE GRAND ARCHIVE"
SCREEN_SUBTITLE :: "A library of lives, memories, and infinite possibilities"