package main

import rl "vendor:raylib"

Player :: struct {
    position:      rl.Vector2,
    radius:        f32,
    speed:         f32,
    config:        Player_Config,
    animation_time: f32,
    facing_left:   bool,
    is_moving:     bool,
    velocity_y:    f32,
    coyote_timer:  f32,
    jump_buffer_timer: f32,
    grounded:      bool,
    is_attacking:  bool,
    attack_variant: int,
    attack_time:   f32,
    attack_cooldown: f32,
    attack_serial: int,
    is_hurt:       bool,
    hurt_time:     f32,
    knockback_x:   f32,
    health:        int,
    max_health:    int,
    invulnerability_time: f32,
    last_hit_enemy: int,
    last_hit_damage: int,
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
    player.position.x += direction * player.speed * dt
    player.animation_time += dt
}

render_player :: proc(player: Player, assets: Game_Assets) {
    texture := assets.player_idle
    frame_count := player.config.idle_frame_count
    if player.is_moving {
        texture = assets.player_run
        frame_count = player.config.run_frame_count
    }

    frame_index := int(player.animation_time / player.config.animation_frame_duration) % frame_count
    source_x := f32(frame_index * player.config.frame_width)
    source_width := f32(player.config.frame_width)
    if player.facing_left {
        source_x += source_width
        source_width = -source_width
    }

    frame_width := f32(player.config.frame_width)
    frame_height := f32(player.config.frame_height)
    scale := player.config.render_scale
    baseline_y := player.position.y + player.radius
    source := rl.Rectangle{source_x, 0, source_width, frame_height}
    destination := rl.Rectangle{
        player.position.x - frame_width * scale / 2,
        baseline_y - frame_height * scale * player.config.ground_anchor,
        frame_width * scale,
        frame_height * scale,
    }
    rl.DrawTexturePro(texture, source, destination, rl.Vector2{0, 0}, 0, rl.WHITE)
}

render_level_player :: proc(player: Player, assets: Game_Assets) {
	texture := assets.player_idle
	frame_count := player.config.idle_frame_count
	frame_duration := player.config.animation_frame_duration

	if player.is_hurt {
		texture = assets.player_hit
		frame_count = 4
		frame_duration = 0.09
		if int(player.hurt_time * 20) % 2 == 0 {
			texture = assets.player_hit_flash
		}
	} else if player.is_attacking {
		if player.attack_variant == 0 {
			texture = assets.player_attack_1
		} else {
			texture = assets.player_attack_2
		}
		frame_count = player.config.attack_frame_count
		frame_duration = player.config.attack_frame_duration
	} else if !player.grounded {
		if player.velocity_y < 0 {
			texture = assets.player_jump
		} else {
			texture = assets.player_fall
		}
		frame_count = 2
		frame_duration = 0.1
	} else if player.is_moving {
		texture = assets.player_run
		frame_count = player.config.run_frame_count
	}

	frame_index := int(player.animation_time / frame_duration) % frame_count
	if player.is_attacking {
		frame_index = int(player.attack_time / frame_duration)
		if frame_index >= frame_count {
			frame_index = frame_count - 1
		}
	}

	frame_width := f32(player.config.frame_width)
	frame_height := f32(player.config.frame_height)
	source_x := f32(frame_index) * frame_width
	source_width := frame_width
	if player.facing_left {
		source_x += source_width
		source_width = -source_width
	}
	scale := player.config.render_scale
	baseline_y := player.position.y + player.radius
	tint := rl.WHITE
	if player.is_hurt && int(player.hurt_time * 24) % 2 == 0 {
		tint = rl.Color{255, 112, 112, 255}
	}
	rl.DrawTexturePro(
		texture,
		rl.Rectangle{source_x, 0, source_width, frame_height},
		rl.Rectangle{
			player.position.x - frame_width * scale / 2,
			baseline_y - frame_height * scale * player.config.ground_anchor,
			frame_width * scale,
			frame_height * scale,
		},
		rl.Vector2{0, 0},
		0,
		tint,
	)
}
