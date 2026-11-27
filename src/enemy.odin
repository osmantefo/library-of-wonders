package main

import "core:math"
import rl "vendor:raylib"

MAX_LEVEL_ENEMIES :: 8
MAX_ENEMY_PROJECTILES :: 32

Enemy :: struct {
	type_id:            Creature_Type,
	position:           rl.Vector2,
	support_y:          f32,
	velocity_y:         f32,
	grounded:           bool,
	home_x:             f32,
	patrol_target:      f32,
	patrol_index:       int,
	patrol_pause:       f32,
	orbit_phase:        f32,
	aggressive:         bool,
	health:             int,
	facing_left:        bool,
	alive:              bool,
	death_time:         f32,
	hurt_time:          f32,
	knockback_x:        f32,
	animation_time:     f32,
	attack_cooldown:    f32,
	melee_cooldown:     f32,
	attack_animation:   f32,
	last_attack_serial: int,
}

Enemy_Projectile :: struct {
	type_id:  Creature_Type,
	position: rl.Vector2,
	velocity: rl.Vector2,
	gravity:  f32,
	damage:   int,
	source_enemy: int,
	age:      f32,
	active:   bool,
}

Level_Run :: struct {
	enemies:          [MAX_LEVEL_ENEMIES]Enemy,
	enemy_count:      int,
	projectiles:      [MAX_ENEMY_PROJECTILES]Enemy_Projectile,
	projectile_count: int,
	animation_time:   f32,
	elapsed_time:     f32,
	damage_taken:     int,
	checkpoint_x:     f32,
	checkpoint_index: int,
	finished:         bool,
	relic_collected:  bool,
}

LEVEL_ENEMY_TYPES :: [MAX_LEVEL_ENEMIES]Creature_Type{
	.FLYING_EYE, .GOBLIN, .MUSHROOM, .SKELETON,
	.FLYING_EYE, .GOBLIN, .MUSHROOM, .SKELETON,
}
LEVEL_ENEMY_X :: [MAX_LEVEL_ENEMIES]f32{1450, 1950, 2500, 3000, 3500, 3950, 4400, 4720}

initialize_level_run :: proc(game: ^Game_State) {
	game.level_run = {}
	game.level_run.checkpoint_x = LEVELS[game.active_level].spawn.x
	if game.active_level != 0 {
		return
	}

	game.level_run.enemy_count = MAX_LEVEL_ENEMIES
	enemy_types := LEVEL_ENEMY_TYPES
	enemy_x := LEVEL_ENEMY_X
	for i in 0..<MAX_LEVEL_ENEMIES {
		type_id := enemy_types[i]
		config := game.creature_catalog[int(type_id)]
		support_y := level_support_y(enemy_x[i])
		if type_id == .FLYING_EYE {
			support_y = level_ground_y()
		}
		game.level_run.enemies[i] = Enemy{
			type_id = type_id,
			home_x = enemy_x[i],
			patrol_target = enemy_x[i] - config.patrol_range,
			support_y = support_y,
			position = {
				enemy_x[i],
				support_y - config.hover_height - config.collision_height / 2,
			},
			health = config.hits_to_kill,
			alive = true,
			grounded = true,
			last_attack_serial = -1,
			patrol_pause = 0.6,
			orbit_phase = f32(i) * 1.7,
		}
	}
}

update_enemies :: proc(game: ^Game_State, dt: f32) {
	run := &game.level_run
	run.animation_time += dt

	for i in 0..<run.enemy_count {
		if game.screen != .LEVEL {
			break
		}
		enemy := &run.enemies[i]
		if !enemy.alive {
			enemy.death_time += dt
			continue
		}

		visible := enemy_is_in_camera(&game.camera, enemy.position.x, 0)
		config := game.creature_catalog[int(enemy.type_id)]
		if visible {
			enemy.animation_time += dt
		}
		enemy.hurt_time = max_f32(0, enemy.hurt_time - dt)
		enemy.attack_cooldown = max_f32(0, enemy.attack_cooldown - dt)
		enemy.melee_cooldown = max_f32(0, enemy.melee_cooldown - dt)
		enemy.attack_animation = max_f32(0, enemy.attack_animation - dt)
		if visible && enemy.type_id != .MUSHROOM {
			enemy.position.x += enemy.knockback_x * dt
		} else if enemy.type_id == .MUSHROOM {
			enemy.knockback_x = 0
		}
		enemy.knockback_x = approach_zero(enemy.knockback_x, 700 * dt)
		update_enemy_ai(game, i, dt, visible)
		enemy.position.x = clamp_f32(enemy.position.x, 48, LEVELS[game.active_level].bounds.width - 48)
		update_enemy_vertical_motion(enemy, config, dt)
	}

	update_enemy_vertical_motion :: proc(enemy: ^Enemy, config: Creature_Config, dt: f32) {
		if enemy.type_id == .FLYING_EYE {
			return
		}
		if enemy.type_id == .MUSHROOM {
			enemy.position.y = enemy.support_y - config.collision_height / 2
			enemy.velocity_y = 0
			enemy.grounded = true
			return
		}

		previous_y := enemy.position.y
		enemy.velocity_y += 1700 * dt
		enemy.position.y += enemy.velocity_y * dt
		ground_y := level_ground_y()
		if enemy.position.y + config.collision_height / 2 >= ground_y {
			enemy.position.y = ground_y - config.collision_height / 2
			enemy.velocity_y = 0
			enemy.grounded = true
			return
		}
		if enemy.velocity_y < 0 {
			enemy.grounded = false
			return
		}
		for platform in LEVEL_PLATFORMS {
			previous_bottom := previous_y + config.collision_height / 2
			current_bottom := enemy.position.y + config.collision_height / 2
			overlaps := enemy.position.x + config.collision_width / 2 > platform.bounds.x &&
			            enemy.position.x - config.collision_width / 2 < platform.bounds.x + platform.bounds.width
			if overlaps && previous_bottom <= platform.bounds.y && current_bottom >= platform.bounds.y {
				enemy.position.y = platform.bounds.y - config.collision_height / 2
				enemy.support_y = platform.bounds.y
				enemy.velocity_y = 0
				enemy.grounded = true
				return
			}
		}
		enemy.grounded = false
	}

	if game.screen != .LEVEL {
		return
	}
	update_enemy_projectiles(game, dt)
}

spawn_enemy_projectile :: proc(game: ^Game_State, enemy_index: int, bomb: bool) -> bool {
	run := &game.level_run
	for i in 0..<MAX_ENEMY_PROJECTILES {
		if run.projectiles[i].active {
			continue
		}
		enemy := run.enemies[enemy_index]
		config := game.creature_catalog[int(enemy.type_id)]
		delta := game.player.position - enemy.position
		distance := math.sqrt(delta.x * delta.x + delta.y * delta.y)
		if distance < 1 {
			distance = 1
		}
		velocity := rl.Vector2{delta.x / distance * config.projectile_speed, delta.y / distance * config.projectile_speed}
		gravity := f32(0)
		damage := config.projectile_damage
		if bomb {
			velocity = {sign_f32(delta.x) * config.projectile_speed, -250}
			gravity = 560
		}
		run.projectiles[i] = Enemy_Projectile{
			type_id = enemy.type_id,
			position = enemy.position,
			velocity = velocity,
			gravity = gravity,
			damage = damage,
			source_enemy = enemy_index,
			active = true,
		}
		run.projectile_count += 1
		enemy_ref := &run.enemies[enemy_index]
		enemy_ref.attack_animation = 0.55
		return true
	}
	return false
}

update_enemy_projectiles :: proc(game: ^Game_State, dt: f32) {
	run := &game.level_run
	for i in 0..<MAX_ENEMY_PROJECTILES {
		projectile := &run.projectiles[i]
		if !projectile.active {
			continue
		}
		config := game.creature_catalog[int(projectile.type_id)]
		projectile.position.x += projectile.velocity.x * dt
		projectile.position.y += projectile.velocity.y * dt
		projectile.velocity.y += projectile.gravity * dt
		projectile.age += dt
		if projectile.age >= 6 ||
		   projectile.position.x < 0 ||
		   projectile.position.x > LEVELS[game.active_level].bounds.width ||
		   projectile.position.y > level_ground_y() + 60 {
			projectile.active = false
			run.projectile_count -= 1
			continue
		}

		if abs_f32(projectile.position.x - game.player.position.x) < f32(config.projectile_frame_width) / 2 + game.player.radius &&
		   abs_f32(projectile.position.y - game.player.position.y) < f32(config.projectile_frame_height) / 2 + game.player.radius {
			apply_player_hit(game, projectile.source_enemy, projectile.damage, sign_f32(projectile.velocity.x), game.player.config.hit_knockback)
			projectile.active = false
			run.projectile_count -= 1
		}
	}
}

render_enemies :: proc(game: ^Game_State) {
	run := game.level_run
	for i in 0..<run.enemy_count {
		enemy := run.enemies[i]
		config := game.creature_catalog[int(enemy.type_id)]
		texture := game.assets.creatures[int(enemy.type_id)].animation
		frame_index := 0
		if enemy.alive && enemy.attack_animation > 0 {
			frame_index = int((0.6 - enemy.attack_animation) / 0.07) % config.frame_count
		}
		if !enemy.alive {
			frame_index = config.frame_count - 1
		}
		source_x := f32(frame_index * config.frame_width)
		source_width := f32(config.frame_width)
		if !enemy.facing_left {
			source_x += source_width
			source_width = -source_width
		}
		tint := rl.WHITE
		if enemy.hurt_time > 0 {
			tint = rl.Color{255, 88, 88, 255}
		} else if !enemy.alive {
			alpha := u8(clamp_f32(255 * (1 - enemy.death_time / 0.45), 0, 255))
			tint = rl.Color{190, 190, 190, alpha}
		}
		scale := f32(1.35)
		rl.DrawTexturePro(
			texture,
			rl.Rectangle{source_x, 0, source_width, f32(config.frame_height)},
			rl.Rectangle{
				enemy.position.x - f32(config.frame_width) * scale / 2,
				enemy.position.y - f32(config.frame_height) * scale / 2,
				f32(config.frame_width) * scale,
				f32(config.frame_height) * scale,
			},
			rl.Vector2{0, 0},
			0,
			tint,
		)
	}

	for i in 0..<MAX_ENEMY_PROJECTILES {
		projectile := run.projectiles[i]
		if !projectile.active {
			continue
		}
		config := game.creature_catalog[int(projectile.type_id)]
		texture := game.assets.creatures[int(projectile.type_id)].projectile
		frame_index := int(projectile.age / 0.08) % config.projectile_frame_count
		source_width := f32(config.projectile_frame_width)
		source_x := f32(frame_index) * source_width
		if projectile.velocity.x > 0 {
			source_x += source_width
			source_width = -source_width
		}
		scale := f32(1.4)
		rl.DrawTexturePro(
			texture,
			rl.Rectangle{source_x, 0, source_width, f32(config.projectile_frame_height)},
			rl.Rectangle{
				projectile.position.x - f32(config.projectile_frame_width) * scale / 2,
				projectile.position.y - f32(config.projectile_frame_height) * scale / 2,
				f32(config.projectile_frame_width) * scale,
				f32(config.projectile_frame_height) * scale,
			},
			rl.Vector2{0, 0},
			0,
			rl.WHITE,
		)
	}
}

max_f32 :: proc(a, b: f32) -> f32 {
	if a > b {
		return a
	}
	return b
}

approach_zero :: proc(value, amount: f32) -> f32 {
	if value > 0 {
		return max_f32(0, value - amount)
	}
	return -max_f32(0, -value - amount)
}

sign_f32 :: proc(value: f32) -> f32 {
	if value < 0 {
		return -1
	}
	if value > 0 {
		return 1
	}
	return 0
}
