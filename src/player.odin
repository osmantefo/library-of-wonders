package main

import rl "vendor:raylib"

Player_Action :: enum {
	NONE,
	ROLL,
	SLIDE,
	PRAY,
	DEATH,
}

Player_Attack_Kind :: enum {
	GROUND,
	AIR,
	PLUNGE,
	CROUCH,
}

Player :: struct {
	position:           rl.Vector2,
	radius:              f32,
	speed:               f32,
	config:              Player_Config,
	animation_time:      f32,
	facing_left:         bool,
	is_moving:            bool,
	is_crouching:         bool,
	velocity_y:           f32,
	coyote_timer:         f32,
	jump_buffer_timer:    f32,
	grounded:             bool,
	is_attacking:         bool,
	attack_kind:          Player_Attack_Kind,
	attack_variant:       int,
	attack_facing_left:   bool,
	attack_time:          f32,
	attack_cooldown:      f32,
	attack_serial:        int,
	action:               Player_Action,
	action_time:          f32,
	action_direction:     f32,
	is_hurt:              bool,
	hurt_time:            f32,
	heal_time:            f32,
	knockback_x:          f32,
	health:               int,
	max_health:           int,
	invulnerability_time: f32,
	last_hit_enemy:       int,
	last_hit_damage:      int,
}

update_player :: proc(player: ^Player, dt: f32) {
	direction := f32(0)
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
		direction -= 1
	}
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
		direction += 1
	}
	player.is_moving = direction != 0
	if player.is_moving {
		player.facing_left = direction < 0
	}
	player.position.x += direction*player.speed*dt
	player.animation_time += dt
}

render_player :: proc(player: Player, assets: Game_Assets) {
	animation := Player_Animation.IDLE
	frame_count := player.config.idle_frame_count
	if player.is_moving {
		animation = .RUN
		frame_count = player.config.run_frame_count
	}
	frame_index := int(player.animation_time / player.config.animation_frame_duration) % frame_count
	draw_player_frame(player, assets, animation, frame_index, rl.WHITE)
}

render_level_player :: proc(player: Player, assets: Game_Assets) {
	animation := Player_Animation.IDLE
	frame_count := player.config.idle_frame_count
	frame_duration := player.config.animation_frame_duration
	frame_index := 0
	frame_start := 0
	tint := rl.WHITE

	switch player.action {
	case .DEATH:
		animation = .DEATH
		frame_count = 4
		frame_duration = 0.15
	case .ROLL:
		animation = .ROLL
		frame_count = 4
		frame_duration = player.config.roll_duration / f32(frame_count)
	case .SLIDE:
		animation = .SLIDE
		frame_count = 12
		frame_duration = player.config.slide_duration / f32(frame_count)
	case .PRAY:
		animation = .PRAY
		frame_count = 12
		frame_duration = 0.12
	case .NONE:
		if player.is_hurt {
			animation = .HURT
			frame_count = 4
			frame_duration = 0.09
			tint = rl.Color{255, 170, 170, 255}
		} else if player.is_attacking {
			switch player.attack_kind {
			case .GROUND:
				animation = .ATTACKS
				frame_count = player.config.attack_frame_count
				frame_start = player.attack_variant * frame_count
			case .AIR:
				animation = .ATTACKS
				frame_count = player.config.attack_frame_count
				frame_start = player.attack_variant * frame_count
			case .PLUNGE:
				animation = .AIR_ATTACK
				frame_count = 8
			case .CROUCH:
				animation = .CROUCH_ATTACK
				frame_count = 8
			}
			frame_duration = player.config.attack_frame_duration
		} else if player.heal_time > 0 {
			animation = .HEALTH
			frame_count = 8
		} else if player.is_crouching {
			animation = .CROUCH_IDLE
			frame_count = 8
		} else if !player.grounded {
			animation = .JUMP
			frame_count = 8
		} else if player.is_moving {
			animation = .RUN
			frame_count = player.config.run_frame_count
		}
	}

	frame_index = int(player.animation_time / frame_duration) % frame_count
	if player.action == .DEATH {
		frame_index = int(player.action_time / frame_duration)
	} else if player.action == .ROLL || player.action == .SLIDE || player.action == .PRAY {
		frame_index = int(player.action_time / frame_duration)
	} else if player.is_attacking {
		frame_index = int(player.attack_time / frame_duration)
	}
	if frame_index >= frame_count {
		frame_index = frame_count - 1
	}
	draw_player_frame(player, assets, animation, frame_start+frame_index, tint)
}

draw_player_frame :: proc(player: Player, assets: Game_Assets, animation: Player_Animation, frame_index: int, tint: rl.Color) {
	texture := assets.player_animations[int(animation)]
	frame_width := i32(player.config.frame_width)
	frame_height := i32(player.config.frame_height)
	columns := int(texture.width / frame_width)
	if columns <= 0 {
		return
	}
	source_x := f32((frame_index % columns) * int(frame_width))
	source_y := f32((frame_index / columns) * int(frame_height))
	source_width := f32(frame_width)
	facing_left := player.facing_left
	if player.is_attacking {
		facing_left = player.attack_facing_left
	}
	flip := facing_left
	if animation == .ATTACKS {
		attack_row := frame_index / player.config.attack_frame_count
		flip = should_flip_player_attack(attack_row, player.attack_facing_left)
	}
	if flip {
		source_x += source_width
		source_width = -source_width
	}

	width := f32(player.config.frame_width)
	height := f32(player.config.frame_height)
	scale := player.config.render_scale
	baseline_y := player.position.y + player.radius
	rl.DrawTexturePro(
		texture,
		rl.Rectangle{source_x, source_y, source_width, f32(frame_height)},
		rl.Rectangle{
			player.position.x - width * scale / 2,
			baseline_y - height * scale * player.config.ground_anchor,
			width * scale,
			height * scale,
		},
		rl.Vector2{0, 0},
		0,
		tint,
	)
}

player_attack_kind_for_input :: proc(grounded, crouching, down_held: bool) -> Player_Attack_Kind {
	if !grounded && down_held {
		return .PLUNGE
	}
	if !grounded {
		return .AIR
	}
	if crouching {
		return .CROUCH
	}
	return .GROUND
}

attack_row_faces_left :: proc(attack_row: int) -> bool {
	return attack_row == 4
}

should_flip_player_attack :: proc(attack_row: int, facing_left: bool) -> bool {
	return facing_left != attack_row_faces_left(attack_row)
}
