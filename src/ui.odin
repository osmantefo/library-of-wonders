package main

import rl "vendor:raylib"

ui_text :: proc(font: rl.Font, text: cstring, x, y, size: i32, color: rl.Color) {
	rl.DrawTextEx(font, text, rl.Vector2{f32(x), f32(y)}, f32(size), 1, color)
}

ui_text_width :: proc(font: rl.Font, text: cstring, size: i32) -> f32 {
	return rl.MeasureTextEx(font, text, f32(size), 1).x
}
