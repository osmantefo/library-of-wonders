package main

import rl "vendor:raylib"

Level_Platform :: struct {
	bounds: rl.Rectangle,
}

LEVEL_PLATFORMS := [4]Level_Platform{
	{{1770, 500, 460, 28}},
	{{2750, 430, 470, 28}},
	{{3700, 490, 500, 28}},
	{{4520, 420, 360, 28}},
}

level_support_y :: proc(world_x: f32) -> f32 {
	support_y := level_ground_y()
	for platform in LEVEL_PLATFORMS {
		if world_x >= platform.bounds.x && world_x <= platform.bounds.x + platform.bounds.width {
			support_y = min_f32(support_y, platform.bounds.y)
		}
	}
	return support_y
}

resolve_player_platform_landing :: proc(player: ^Player, previous_y: f32) -> bool {
	if player.velocity_y < 0 {
		return false
	}

	previous_bottom := previous_y + player.radius
	current_bottom := player.position.y + player.radius
	for platform in LEVEL_PLATFORMS {
		top := platform.bounds.y
		horizontally_overlaps := player.position.x + player.radius > platform.bounds.x &&
		                         player.position.x - player.radius < platform.bounds.x + platform.bounds.width
		if horizontally_overlaps && previous_bottom <= top && current_bottom >= top {
			player.position.y = top - player.radius
			player.velocity_y = 0
			player.grounded = true
			return true
		}
	}
	return false
}

render_level_platforms :: proc() {
	for platform in LEVEL_PLATFORMS {
		rl.DrawRectangleRec(platform.bounds, rl.Color{44, 37, 63, 255})
		rl.DrawRectangle(i32(platform.bounds.x), i32(platform.bounds.y), i32(platform.bounds.width), 6, rl.Color{141, 110, 190, 255})
		rl.DrawRectangleLinesEx(platform.bounds, 2, rl.Color{91, 77, 123, 255})
	}
}
