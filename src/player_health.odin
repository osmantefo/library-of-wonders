package main

import rl "vendor:raylib"

HEALTH_FEEDBACK_DURATION :: f32(1.2)
HEALTH_METER_FRAME_WIDTH :: 64
HEALTH_METER_FRAME_HEIGHT :: 16
HEALTH_METER_SCALE :: f32(3)

apply_player_hit :: proc(game: ^Game_State, source_enemy: int, damage: int, direction, force: f32) {
	player := &game.player
	if player.invulnerability_time > 0 || player.health <= 0 {
		return
	}

	feedback_start_ratio := player_health_ratio(player^)
	actual_damage := min_int(damage, player.health)
	player.health -= actual_damage
	player.health_feedback = .DAMAGE
	player.health_feedback_time = HEALTH_FEEDBACK_DURATION
	player.health_feedback_amount = actual_damage
	player.health_feedback_tier = health_feedback_tier_for_amount(actual_damage, player.max_health)
	player.health_feedback_start_ratio = feedback_start_ratio
	player.health_feedback_end_ratio = player_health_ratio(player^)
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
	player.is_attacking = false
	player.action = .NONE
	if player.grounded {
		player.velocity_y = -player.config.jump_speed * 0.28
		player.grounded = false
	}
	if player.health <= 0 {
		player.action = .DEATH
		player.action_time = 0
		player.is_crouching = false
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
	feedback_start_ratio := player_health_ratio(player^)
	previous_health := player.health
	player.health = min_int(player.max_health, player.health+recovered)
	if player.health > previous_health {
		player.heal_time = 0.72
		player.health_feedback = .HEAL
		player.health_feedback_time = HEALTH_FEEDBACK_DURATION
		player.health_feedback_amount = player.health-previous_health
		player.health_feedback_tier = health_feedback_tier_for_amount(player.health_feedback_amount, player.max_health)
		player.health_feedback_start_ratio = feedback_start_ratio
		player.health_feedback_end_ratio = player_health_ratio(player^)
	}
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

health_feedback_tier_for_amount :: proc(amount, max_health: int) -> UI_Animation {
	if max_health <= 0 || amount*10 <= max_health {
		return .MINIMUM_DAMAGE
	}
	if amount*4 <= max_health {
		return .MEDIUM_DAMAGE
	}
	return .CRITICAL_DAMAGE
}

player_health_ratio :: proc(player: Player) -> f32 {
	if player.max_health <= 0 {
		return 0
	}
	return clamp_f32(f32(player.health)/f32(player.max_health), 0, 1)
}

player_health_feedback_ratio :: proc(player: Player) -> f32 {
	if player.health_feedback == .NONE || player.health_feedback_time <= 0 {
		return player_health_ratio(player)
	}
	progress := clamp_f32(
		(HEALTH_FEEDBACK_DURATION-player.health_feedback_time)/HEALTH_FEEDBACK_DURATION,
		0,
		1,
	)
	return player.health_feedback_start_ratio +
	       (player.health_feedback_end_ratio-player.health_feedback_start_ratio)*progress
}

render_player_health :: proc(game: ^Game_State) {
	draw_ui_nine_slice(
		game.assets.ui_inventory,
		{16, 48, 48, 48},
		{16, 24, 64, 64},
		8,
		10,
		rl.WHITE,
	)

	idle := game.assets.player_animations[int(Player_Animation.IDLE)]
	rl.DrawTexturePro(
		idle,
		{56, 14, 16, 16},
		{24, 32, 48, 48},
		{0, 0},
		0,
		rl.WHITE,
	)

	ratio := player_health_ratio(game.player)
	animation := UI_Animation.MINIMUM_DAMAGE
	frame_counts := UI_ANIMATION_FRAME_COUNTS
	frame_count := frame_counts[int(animation)]
	frame := health_meter_frame(ratio, frame_count)
	if game.player.health_feedback != .NONE && game.player.health_feedback_time > 0 {
		animation = game.player.health_feedback_tier
		frame_count = frame_counts[int(animation)]
		ratio = player_health_feedback_ratio(game.player)
		frame = health_meter_frame(ratio, frame_count)
	}
	render_health_feedback(game, animation, frame)
}

health_meter_frame :: proc(health_ratio: f32, frame_count: int) -> int {
	if frame_count <= 1 {
		return 0
	}
	frame := int((1-health_ratio)*f32(frame_count-1) + 0.5)
	if frame < 0 {
		return 0
	}
	if frame >= frame_count {
		return frame_count-1
	}
	return frame
}

render_health_feedback :: proc(game: ^Game_State, animation: UI_Animation, frame: int) {
	animation_index := int(animation)
	frame_heights := UI_ANIMATION_FRAME_HEIGHTS
	frame_height := frame_heights[animation_index]
	if animation != .MINIMUM_DAMAGE && animation != .MEDIUM_DAMAGE && animation != .CRITICAL_DAMAGE {
		animation_index = int(UI_Animation.MINIMUM_DAMAGE)
		frame_height = frame_heights[animation_index]
	}
	rl.DrawTexturePro(
		game.assets.ui_animations[animation_index],
		{0, f32(frame*frame_height), HEALTH_METER_FRAME_WIDTH, HEALTH_METER_FRAME_HEIGHT},
		{80, 32, HEALTH_METER_FRAME_WIDTH*HEALTH_METER_SCALE, HEALTH_METER_FRAME_HEIGHT*HEALTH_METER_SCALE},
		{0, 0},
		0,
		rl.WHITE,
	)
}

draw_ui_nine_slice :: proc(texture: rl.Texture2D, source, destination: rl.Rectangle, source_border, destination_border: f32, tint: rl.Color) {
	src_border_x := min_f32(source_border, source.width/2)
	src_border_y := min_f32(source_border, source.height/2)
	dst_border_x := min_f32(destination_border, destination.width/2)
	dst_border_y := min_f32(destination_border, destination.height/2)
	source_x := [3]f32{source.x, source.x+src_border_x, source.x+source.width-src_border_x}
	source_y := [3]f32{source.y, source.y+src_border_y, source.y+source.height-src_border_y}
	source_width := [3]f32{src_border_x, source.width-2*src_border_x, src_border_x}
	source_height := [3]f32{src_border_y, source.height-2*src_border_y, src_border_y}
	destination_x := [3]f32{destination.x, destination.x+dst_border_x, destination.x+destination.width-dst_border_x}
	destination_y := [3]f32{destination.y, destination.y+dst_border_y, destination.y+destination.height-dst_border_y}
	destination_width := [3]f32{dst_border_x, destination.width-2*dst_border_x, dst_border_x}
	destination_height := [3]f32{dst_border_y, destination.height-2*dst_border_y, dst_border_y}
	for row in 0..<3 {
		for column in 0..<3 {
			rl.DrawTexturePro(
				texture,
				{source_x[column], source_y[row], source_width[column], source_height[row]},
				{destination_x[column], destination_y[row], destination_width[column], destination_height[row]},
				{0, 0},
				0,
				tint,
			)
		}
	}
}
