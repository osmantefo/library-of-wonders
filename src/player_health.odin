package main

import rl "vendor:raylib"

apply_player_hit :: proc(game: ^Game_State, source_enemy: int, damage: int, direction, force: f32) {
	player := &game.player
	if player.invulnerability_time > 0 || player.health <= 0 {
		return
	}

	actual_damage := min_int(damage, player.health)
	player.health -= actual_damage
	game.level_run.damage_taken += actual_damage
	if player.last_hit_enemy == source_enemy {
		player.last_hit_damage += actual_damage
	} else {
		player.last_hit_enemy = source_enemy
		player.last_hit_damage = actual_damage
	}
	player.hurt_time = 0.75
	player.invulnerability_time = 0.65
	player.is_hurt = true
	player.knockback_x = direction * force
	if player.grounded {
		player.velocity_y = -player.config.jump_speed * 0.28
		player.grounded = false
	}
	if player.health <= 0 {
		respawn_at_checkpoint(game)
	}
}

siphon_last_attacker :: proc(game: ^Game_State, defeated_enemy: int) {
	player := &game.player
	if player.last_hit_enemy != defeated_enemy || player.last_hit_damage <= 0 {
		return
	}
	recovered := int(f32(player.last_hit_damage) * player.config.siphon_fraction)
	if recovered < 1 {
		recovered = 1
	}
	player.health = min_int(player.max_health, player.health+recovered)
	player.last_hit_enemy = -1
	player.last_hit_damage = 0
}

min_f32 :: proc(a, b: f32) -> f32 {
	if a < b {
		return a
	}
	return b
}

min_int :: proc(a, b: int) -> int {
	if a < b {
		return a
	}
	return b
}

render_player_health :: proc(game: ^Game_State) {
	bar_width := i32(240)
	bar_height := i32(22)
	x := i32(WINDOW_WIDTH - 28 - bar_width)
	y := i32(24)
	rl.DrawRectangle(x, y, bar_width, bar_height, rl.Color{25, 20, 33, 230})
	rl.DrawRectangleLines(x, y, bar_width, bar_height, rl.Color{236, 228, 213, 255})
	fill_width := i32(f32(bar_width-4) * f32(game.player.health) / f32(game.player.max_health))
	if fill_width > 0 {
		color := rl.Color{89, 205, 132, 255}
		if game.player.health * 4 <= game.player.max_health {
			color = rl.Color{232, 78, 82, 255}
		} else if game.player.health * 2 <= game.player.max_health {
			color = rl.Color{238, 174, 76, 255}
		}
		rl.DrawRectangle(x+2, y+2, fill_width, bar_height-4, color)
	}
	health_label := rl.TextFormat("%d / %d HP", game.player.health, game.player.max_health)
	ui_text(game.assets.ui_font, health_label, x, y+bar_height+5, 16, COLOR_TEXT)
}
