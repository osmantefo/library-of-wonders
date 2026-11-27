package main

import rl "vendor:raylib"

LEVEL_GROUND_Y :: f32(WINDOW_HEIGHT) * 0.84

level_ground_y :: proc() -> f32 {
	return LEVEL_GROUND_Y
}

update_platformer_player :: proc(game: ^Game_State, dt: f32) {
	player := &game.player
	player.animation_time += dt
	player.is_hurt = player.hurt_time > 0
	player.hurt_time = max_f32(0, player.hurt_time-dt)
	player.heal_time = max_f32(0, player.heal_time-dt)
	player.invulnerability_time = max_f32(0, player.invulnerability_time-dt)
	player.attack_cooldown = max_f32(0, player.attack_cooldown-dt)
	if player.is_attacking {
		player.attack_time += dt
		if player.attack_time >= f32(player.config.attack_frame_count)*player.config.attack_frame_duration {
			player.is_attacking = false
		}
	}

	if player.action == .DEATH {
		player.action_time += dt
		if player.action_time >= 0.6 {
			respawn_at_checkpoint(game)
		}
		return
	}

	direction := f32(0)
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
		direction -= 1
	}
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
		direction += 1
	}
	player.is_moving = direction != 0
	if player.is_moving && !player.is_attacking {
		player.facing_left = direction < 0
	}

	jump_pressed := rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP)
	crouch_held := rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)
	attack_pressed := rl.IsKeyPressed(.J) || rl.IsKeyPressed(.X)

	if player.action == .ROLL || player.action == .SLIDE {
		player.action_time += dt
		action_speed := player.config.roll_speed
		action_duration := player.config.roll_duration
		if player.action == .SLIDE {
			action_speed = player.config.slide_speed
			action_duration = player.config.slide_duration
		}
		player.position.x += player.action_direction * action_speed * dt
		player.grounded = true
		player.velocity_y = 0
		if player.action_time >= action_duration {
			player.action = .NONE
			player.action_time = 0
		}
		player.position.x = clamp_f32(player.position.x, player.radius, LEVELS[game.active_level].bounds.width-player.radius)
		update_player_attack(game)
		return
	}
	if player.action == .PRAY {
		if direction != 0 || jump_pressed || attack_pressed || crouch_held {
			player.action = .NONE
			player.action_time = 0
		} else {
			player.action_time += dt
			if player.action_time >= 1.44 {
				player.action = .NONE
				player.action_time = 0
			}
			return
		}
	}

	if player.grounded {
		player.coyote_timer = player.config.coyote_time
	} else {
		player.coyote_timer = max_f32(0, player.coyote_timer-dt)
	}
	if jump_pressed {
		player.jump_buffer_timer = player.config.jump_buffer_time
	} else {
		player.jump_buffer_timer = max_f32(0, player.jump_buffer_timer-dt)
	}
	if can_start_buffered_jump(player.grounded, player.coyote_timer, player.jump_buffer_timer) && !crouch_held {
		player.velocity_y = -player.config.jump_speed
		player.grounded = false
		player.coyote_timer = 0
		player.jump_buffer_timer = 0
	}
	jump_held := rl.IsKeyDown(.SPACE) || rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)
	player.velocity_y = apply_jump_cut(player.velocity_y, player.config.jump_speed, player.config.jump_cut_multiplier, jump_held)
	previous_y := player.position.y

	if player.hurt_time <= 0 {
		move_speed := player.speed
		player.is_crouching = player.grounded && crouch_held
		if player.is_crouching {
			move_speed *= player.config.crouch_move_multiplier
		}
		player.position.x += direction * move_speed * dt
	}
	player.position.x += player.knockback_x*dt
	player.knockback_x = approach_zero(player.knockback_x, 900*dt)

	player.grounded = false
	player.velocity_y += player.config.gravity*dt
	player.position.y += player.velocity_y*dt
	ground_center := level_ground_y()-player.radius
	if player.position.y >= ground_center {
		player.position.y = ground_center
		player.velocity_y = 0
		player.grounded = true
	} else {
		resolve_player_platform_landing(player, previous_y)
	}

	if player.action == .NONE && !player.is_attacking && player.grounded && crouch_held && direction != 0 &&
	   (rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN)) {
		player.action = .SLIDE
		player.action_time = 0
		player.action_direction = direction
		player.is_crouching = false
	} else if player.action == .NONE && !player.is_attacking && player.grounded &&
	          (rl.IsKeyPressed(.LEFT_SHIFT) || rl.IsKeyPressed(.RIGHT_SHIFT)) {
		player.action = .ROLL
		player.action_time = 0
		player.action_direction = -1
		if !player.facing_left {
			player.action_direction = 1
		}
		player.invulnerability_time = max_f32(player.invulnerability_time, player.config.roll_duration*0.55)
		player.is_crouching = false
	} else if player.action == .NONE && player.grounded && rl.IsKeyPressed(.P) &&
	          !player.is_moving && !player.is_attacking {
		player.action = .PRAY
		player.action_time = 0
		player.is_crouching = false
	}

	if attack_pressed && !player.is_attacking && player.attack_cooldown <= 0 &&
	   player.action == .NONE && player.hurt_time <= 0 {
		player.attack_kind = player_attack_kind_for_input(player.grounded, player.is_crouching, crouch_held)
		if player.attack_kind == .GROUND || player.attack_kind == .AIR {
			player.attack_variant = player.attack_serial % 5
		}
		player.attack_facing_left = player.facing_left
		if player.attack_kind == .PLUNGE {
			player.velocity_y = max_f32(player.velocity_y, player.config.jump_speed*1.25)
		}
		player.attack_serial += 1
		player.attack_time = 0
		player.attack_cooldown = player.config.attack_cooldown
		player.is_attacking = true
	}

	player.position.x = clamp_f32(player.position.x, player.radius, LEVELS[game.active_level].bounds.width-player.radius)
	update_player_attack(game)
}

can_start_buffered_jump :: proc(grounded: bool, coyote_timer, jump_buffer_timer: f32) -> bool {
	return jump_buffer_timer > 0 && (grounded || coyote_timer > 0)
}

apply_jump_cut :: proc(velocity_y, jump_speed, cut_multiplier: f32, jump_held: bool) -> f32 {
	if velocity_y < 0 && !jump_held {
		return max_f32(velocity_y, -jump_speed*cut_multiplier)
	}
	return velocity_y
}

update_player_attack :: proc(game: ^Game_State) {
	player := &game.player
	if !player.is_attacking || player.attack_time < 0.12 || player.attack_time > 0.42 {
		return
	}

	for i in 0..<game.level_run.enemy_count {
		enemy := &game.level_run.enemies[i]
		if !enemy.alive || enemy.last_attack_serial == player.attack_serial {
			continue
		}
		config := game.creature_catalog[int(enemy.type_id)]
		delta_x := enemy.position.x-player.position.x
		vertical_range := f32(85)
		horizontal_range := player.config.attack_range+config.collision_width/2
		if player.attack_kind == .AIR {
			vertical_range = 130
		} else if player.attack_kind == .PLUNGE {
			vertical_range = 200
			horizontal_range = player.radius+config.collision_width/2+24
			if enemy.position.y <= player.position.y ||
			   abs_f32(delta_x) > horizontal_range {
				continue
			}
		} else if player.attack_kind == .CROUCH {
			vertical_range = 45
		}
		if abs_f32(delta_x) > horizontal_range ||
		   abs_f32(enemy.position.y-player.position.y) > config.collision_height/2+vertical_range ||
		   (player.attack_kind != .PLUNGE && player.attack_facing_left && delta_x > 0) ||
		   (player.attack_kind != .PLUNGE && !player.attack_facing_left && delta_x < 0) {
			continue
		}

		knockback_direction := sign_f32(delta_x)
		if player.attack_kind == .PLUNGE {
			knockback_direction = 0
		} else if player.attack_facing_left {
			knockback_direction = -abs_f32(knockback_direction)
		} else {
			knockback_direction = abs_f32(knockback_direction)
		}
		damage_enemy(game, i, player.attack_serial, knockback_direction*player.config.hit_knockback)
	}
}

damage_enemy :: proc(game: ^Game_State, enemy_index: int, attack_serial: int, knockback: f32) -> bool {
	enemy := &game.level_run.enemies[enemy_index]
	if !enemy.alive || enemy.last_attack_serial == attack_serial {
		return false
	}
	enemy.health -= 1
	enemy.last_attack_serial = attack_serial
	enemy.hurt_time = 0.24
	if enemy.type_id != .MUSHROOM {
		enemy.knockback_x = knockback
	}
	if enemy.health <= 0 {
		enemy.alive = false
		enemy.death_time = 0
		siphon_last_attacker(game, enemy_index)
	}
	return true
}
