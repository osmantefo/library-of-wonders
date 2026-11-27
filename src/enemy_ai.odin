package main

import "core:math"
import rl "vendor:raylib"

enemy_is_in_camera :: proc(camera: ^rl.Camera2D, world_x, margin: f32) -> bool {
	half_width := camera.offset.x / camera.zoom
	return abs_f32(world_x - camera.target.x) <= half_width + margin
}

update_enemy_ai :: proc(game: ^Game_State, enemy_index: int, dt: f32, visible: bool = true) {
	enemy := &game.level_run.enemies[enemy_index]
	config := game.creature_catalog[int(enemy.type_id)]
	delta_x := game.player.position.x - enemy.position.x
	distance_x := abs_f32(delta_x)
	distance_y := abs_f32(game.player.position.y - enemy.position.y)
	enemy.facing_left = delta_x < 0

	switch enemy.type_id {
	case .FLYING_EYE:
		if visible {
			update_flying_eye(game, enemy_index, dt, config, distance_x)
		}
	case .MUSHROOM:
		if visible {
			update_mushroom(game, enemy_index, config, distance_x, distance_y)
		}
	case .GOBLIN:
		update_goblin(game, enemy_index, dt, config, distance_x, visible)
	case .SKELETON:
		update_skeleton(game, enemy_index, dt, config, distance_x, visible)
	}
}

update_flying_eye :: proc(game: ^Game_State, enemy_index: int, dt: f32, config: Creature_Config, distance_x: f32) {
	enemy := &game.level_run.enemies[enemy_index]
	distance_y := abs_f32(game.player.position.y - enemy.position.y)

	enemy.orbit_phase += dt * 1.6
	target_x := game.player.position.x + math.cos(enemy.orbit_phase) * config.orbit_radius
	target_y := game.player.position.y - 95 + math.sin(enemy.orbit_phase * 0.8) * 30
	enemy.position.x = move_towards(enemy.position.x, target_x, config.move_speed * 1.8 * dt)
	enemy.position.y = move_towards(enemy.position.y, target_y, config.move_speed * dt)
	enemy.facing_left = game.player.position.x < enemy.position.x

	if distance_x <= config.attack_range && enemy.attack_cooldown <= 0 {
		if spawn_enemy_projectile(game, enemy_index, false) {
			enemy.attack_cooldown = 1.8
			enemy.attack_animation = 0.55
		}
	}
	if distance_x < config.collision_width/2+32 && distance_y < config.collision_height/2+48 {
		enemy_melee_player(game, enemy_index, config.attack_damage, 0.9)
	}
}

update_mushroom :: proc(game: ^Game_State, enemy_index: int, config: Creature_Config, distance_x, distance_y: f32) {
	enemy := &game.level_run.enemies[enemy_index]
	enemy.position.y = enemy.support_y - config.collision_height/2
	enemy.facing_left = game.player.position.x < enemy.position.x
	in_contact := distance_x < config.collision_width/2+game.player.radius &&
	              distance_y < config.collision_height/2+game.player.radius+20
	if in_contact {
		enemy_melee_player(game, enemy_index, config.attack_damage, 0.72)
		return
	}

	if distance_x <= config.attack_range && enemy.attack_cooldown <= 0 {
		if spawn_enemy_projectile(game, enemy_index, false) {
			enemy.attack_cooldown = 2.0
			enemy.attack_animation = 0.55
		}
	}
}

update_goblin :: proc(game: ^Game_State, enemy_index: int, dt: f32, config: Creature_Config, distance_x: f32, visible: bool) {
	enemy := &game.level_run.enemies[enemy_index]
	if visible && !enemy.aggressive && distance_x <= config.aggro_range {
		enemy.aggressive = true
	}
	if !enemy.aggressive {
		if enemy.patrol_pause > 0 {
			enemy.patrol_pause -= dt
			return
		}
		if move_patrol_enemy(enemy, enemy.patrol_target, config.move_speed*0.65, dt) {
			if enemy.patrol_target <= enemy.home_x-config.patrol_range {
				enemy.patrol_target = enemy.home_x + config.patrol_range
			} else {
				enemy.patrol_target = enemy.home_x - config.patrol_range
			}
			enemy.patrol_pause = 0.45
		}
		return
	}
	if !visible {
		return
	}

	delta_x := game.player.position.x - enemy.position.x
	enemy.facing_left = delta_x < 0
	if distance_x > config.attack_range+config.collision_width/2 {
		enemy.position.x += sign_f32(delta_x) * config.move_speed * dt
	}
	if distance_x > config.attack_range+36 && distance_x < 360 && enemy.attack_cooldown <= 0 {
		if spawn_enemy_projectile(game, enemy_index, true) {
			enemy.attack_cooldown = 2.8
			enemy.attack_animation = 0.7
		}
	}
	enemy_melee_player(game, enemy_index, config.attack_damage, 1.0)
}

update_skeleton :: proc(game: ^Game_State, enemy_index: int, dt: f32, config: Creature_Config, distance_x: f32, visible: bool) {
	enemy := &game.level_run.enemies[enemy_index]
	if visible && !enemy.aggressive && distance_x <= config.aggro_range {
		enemy.aggressive = true
	}
	if enemy.aggressive {
		if !visible {
			return
		}
		delta_x := game.player.position.x - enemy.position.x
		enemy.facing_left = delta_x < 0
		if distance_x > config.attack_range+config.collision_width/2 {
			enemy.position.x += sign_f32(delta_x) * config.move_speed * dt
		}
		enemy_melee_player(game, enemy_index, config.attack_damage, 1.15)
		return
	}

	if enemy.patrol_pause > 0 {
		enemy.patrol_pause -= dt
		return
	}

	if move_patrol_enemy(enemy, enemy.patrol_target, config.move_speed*0.55, dt) {
		enemy.patrol_index = (enemy.patrol_index + 1) % 4
		switch enemy.patrol_index {
		case 0: enemy.patrol_target = enemy.home_x - config.patrol_range
		case 1: enemy.patrol_target = enemy.home_x
		case 2: enemy.patrol_target = enemy.home_x + config.patrol_range
		case 3: enemy.patrol_target = enemy.home_x + config.patrol_range*0.45
		}
		enemy.patrol_pause = 1.35
	}
}

move_patrol_enemy :: proc(enemy: ^Enemy, target_x, speed, dt: f32) -> bool {
	delta_x := target_x - enemy.position.x
	enemy.facing_left = delta_x < 0
	if abs_f32(delta_x) <= speed*dt {
		enemy.position.x = target_x
		return true
	}
	enemy.position.x += sign_f32(delta_x) * speed * dt
	return false
}

enemy_melee_player :: proc(game: ^Game_State, enemy_index: int, damage: int, cooldown: f32) {
	enemy := &game.level_run.enemies[enemy_index]
	config := game.creature_catalog[int(enemy.type_id)]
	if enemy.melee_cooldown > 0 {
		return
	}
	if abs_f32(game.player.position.x-enemy.position.x) > config.attack_range ||
	   abs_f32(game.player.position.y-enemy.position.y) > config.collision_height/2+game.player.radius+22 {
		return
	}

	enemy.melee_cooldown = cooldown
	enemy.attack_animation = 0.5
	knockback_direction := sign_f32(game.player.position.x-enemy.position.x)
	if knockback_direction == 0 && enemy.facing_left {
		knockback_direction = 1
	} else if knockback_direction == 0 {
		knockback_direction = -1
	}
	apply_player_hit(game, enemy_index, damage, knockback_direction, game.player.config.hit_knockback)
}

move_towards :: proc(value, target, amount: f32) -> f32 {
	delta := target - value
	if abs_f32(delta) <= amount {
		return target
	}
	return value + sign_f32(delta)*amount
}
