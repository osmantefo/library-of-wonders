package main

import "core:testing"
import "core:encoding/json"

@(test)
test_player_config_loads_from_data_file :: proc(t: ^testing.T) {
    config := load_player_config()

    testing.expect(t, config.move_speed > 0)
    testing.expect(t, config.radius > 0)
    testing.expect_value(t, config.frame_width, 200)
    testing.expect_value(t, config.frame_height, 200)
    testing.expect_value(t, config.idle_frame_count, 8)
    testing.expect_value(t, config.run_frame_count, 8)
    testing.expect(t, config.animation_frame_duration > 0)
    testing.expect(t, config.render_scale > 0)
    testing.expect(t, config.ground_anchor > 0 && config.ground_anchor <= 1)
    testing.expect(t, config.jump_speed > 0 && config.gravity > 0)
    testing.expect(t, config.coyote_time > 0 && config.jump_buffer_time > 0)
    testing.expect(t, config.jump_cut_multiplier > 0 && config.jump_cut_multiplier < 1)
    jump_apex_height := config.jump_speed * config.jump_speed / (2 * config.gravity)
    jump_airtime := 2 * config.jump_speed / config.gravity
    testing.expect(t, jump_apex_height >= 300)
    testing.expect(t, jump_airtime >= 1.5)
    testing.expect(t, config.attack_frame_count > 0 && config.attack_range > 0)
}

@(test)
test_jump_buffer_coyote_time_and_variable_jump_helpers :: proc(t: ^testing.T) {
	testing.expect_value(t, can_start_buffered_jump(false, 0.1, 0.1), true)
	testing.expect_value(t, can_start_buffered_jump(false, 0, 0.1), false)
	testing.expect_value(t, can_start_buffered_jump(true, 0, 0), false)
	testing.expect_value(t, apply_jump_cut(-850, 850, 0.48, false), -408.0)
	testing.expect_value(t, apply_jump_cut(-850, 850, 0.48, true), -850.0)
	testing.expect_value(t, apply_jump_cut(220, 850, 0.48, false), 220.0)
}

@(test)
test_level_checkpoints_activate_in_order :: proc(t: ^testing.T) {
	game := Game_State{active_level = 0}
	game.level_run.checkpoint_x = 120
	game.player.position.x = 2300

	activate_level_checkpoint(&game)

	testing.expect_value(t, game.level_run.checkpoint_x, 2240.0)
	testing.expect_value(t, game.level_run.checkpoint_index, 1)
	game.player.position.x = 4300
	activate_level_checkpoint(&game)
	testing.expect_value(t, game.level_run.checkpoint_x, 4260.0)
	testing.expect_value(t, game.level_run.checkpoint_index, 2)
}

@(test)
test_platform_landing_and_jump_through :: proc(t: ^testing.T) {
	platform := LEVEL_PLATFORMS[1].bounds
	player := Player{
		position = {platform.x + 30, platform.y - 13 + 4},
		radius = 13,
		velocity_y = 120,
	}

	testing.expect_value(t, resolve_player_platform_landing(&player, platform.y - 13 - 5), true)
	testing.expect_value(t, player.position.y, platform.y - player.radius)
	testing.expect_value(t, player.velocity_y, 0.0)
	testing.expect_value(t, player.grounded, true)

	player.position.y = platform.y - player.radius + 10
	player.velocity_y = -100
	player.grounded = false
	testing.expect_value(t, resolve_player_platform_landing(&player, player.position.y + 5), false)
}

@(test)
test_selected_enemies_spawn_on_platforms :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	initialize_level_run(&game)

	testing.expect_value(t, game.level_run.enemies[1].support_y, LEVEL_PLATFORMS[0].bounds.y)
	testing.expect_value(t, game.level_run.enemies[3].support_y, LEVEL_PLATFORMS[1].bounds.y)
}

@(test)
test_relic_details_are_hidden_until_book_clear :: proc(t: ^testing.T) {
	progress := Book_Progress{relics_found = 1}
	testing.expect_value(t, relic_information_available(progress), false)
	progress.cleared = true
	testing.expect_value(t, relic_information_available(progress), true)
}

@(test)
test_new_game_resets_saved_progression_state :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)

	game.progression.books[0] = Book_Progress{cleared = true, relics_found = 1}
	game.progression.books[4] = Book_Progress{cleared = true}
	game.world.books[0].completed = true
	game.world.books[4].completed = true

	reset_progression_state(&game)

	testing.expect_value(t, game.progression.books[0].cleared, false)
	testing.expect_value(t, game.progression.books[0].relics_found, 0)
	testing.expect_value(t, game.progression.books[4].cleared, false)
	testing.expect_value(t, game.world.books[0].completed, false)
	testing.expect_value(t, game.world.books[4].completed, false)
}

@(test)
test_progression_json_round_trip :: proc(t: ^testing.T) {
	expected := Progression{}
	expected.books[0] = Book_Progress{cleared = true, relics_found = 1}
	expected.books[4] = Book_Progress{cleared = true}
	data, marshal_error := json.marshal(expected, {pretty = true})
	testing.expect(t, marshal_error == nil)
	if marshal_error != nil {
		return
	}
	defer delete(data)

	actual: Progression
	testing.expect_value(t, decode_progression(data, &actual), true)
	testing.expect_value(t, actual.books[0].cleared, true)
	testing.expect_value(t, actual.books[0].relics_found, 1)
	testing.expect_value(t, actual.books[4].cleared, true)
	testing.expect_value(t, actual.books[4].relics_found, 0)
}

@(test)
test_clearing_level_without_relic_keeps_optional_relic_unfound :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0

	record_level_completion(&game)

	testing.expect_value(t, game.world.books[0].completed, true)
	testing.expect_value(t, game.progression.books[0].cleared, true)
	testing.expect_value(t, game.progression.books[0].relics_found, 0)
}

@(test)
test_clearing_level_after_relic_pickup_records_it :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	game.level_run.relic_collected = true

	record_level_completion(&game)

	testing.expect_value(t, game.progression.books[0].cleared, true)
	testing.expect_value(t, game.progression.books[0].relics_found, 1)
}

@(test)
test_creature_catalog_has_requested_hit_counts :: proc(t: ^testing.T) {
	catalog := load_creature_catalog()

	testing.expect_value(t, len(catalog), CREATURE_COUNT)
	testing.expect_value(t, catalog[int(Creature_Type.FLYING_EYE)].hits_to_kill, 1)
	testing.expect_value(t, catalog[int(Creature_Type.MUSHROOM)].hits_to_kill, 1)
	testing.expect_value(t, catalog[int(Creature_Type.GOBLIN)].hits_to_kill, 2)
	testing.expect_value(t, catalog[int(Creature_Type.SKELETON)].hits_to_kill, 3)
}

@(test)
test_first_level_spawns_two_of_each_creature :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	initialize_level_run(&game)

	testing.expect_value(t, game.level_run.enemy_count, MAX_LEVEL_ENEMIES)
	counts := [CREATURE_COUNT]int{}
	for enemy in game.level_run.enemies {
		counts[int(enemy.type_id)] += 1
		testing.expect_value(t, enemy.alive, true)
	}
	for count in counts {
		testing.expect_value(t, count, 2)
	}
}

@(test)
test_creatures_take_the_configured_number_of_distinct_hits :: proc(t: ^testing.T) {
	catalog := load_creature_catalog()
	for i in 0..<CREATURE_COUNT {
		config := catalog[i]
		enemy := Enemy{
			type_id = Creature_Type(i),
			health = config.hits_to_kill,
			alive = true,
			last_attack_serial = -1,
		}
		game := Game_State{}
		game.level_run.enemies[0] = enemy
		for hit in 0..<config.hits_to_kill {
			testing.expect_value(t, damage_enemy(&game, 0, hit, 100), true)
			enemy = game.level_run.enemies[0]
			if hit + 1 < config.hits_to_kill {
				testing.expect_value(t, enemy.alive, true)
			}
		}
		testing.expect_value(t, enemy.alive, false)
		testing.expect_value(t, damage_enemy(&game, 0, config.hits_to_kill + 1, 100), false)
	}
}

@(test)
test_level_exit_records_completion_and_returns_to_lobby :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	game.screen = .LEVEL
	game.lobby_return_position = {345, 555}
	game.lobby_return_floor = 1

	record_level_completion(&game)
	return_to_lobby(&game, false)

	testing.expect_value(t, game.screen, Screen.LOBBY)
	testing.expect_value(t, game.world.books[0].completed, true)
	testing.expect_value(t, game.player.position.x, 345.0)
	testing.expect_value(t, game.player.position.y, 555.0)
	testing.expect_value(t, game.floor_index, 1)
}

@(test)
test_killing_last_enemy_to_hit_player_siphons_health :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	game.player.health = 60
	game.player.last_hit_enemy = 2
	game.player.last_hit_damage = 40
	game.level_run.enemies[2] = Enemy{health = 1, alive = true, last_attack_serial = -1}

	testing.expect_value(t, damage_enemy(&game, 2, 1, 100), true)

	testing.expect_value(t, game.player.health, 78)
	testing.expect_value(t, game.player.last_hit_enemy, -1)
}

@(test)
test_killing_other_enemy_does_not_siphon_recent_damage :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	game.player.health = 60
	game.player.last_hit_enemy = 1
	game.player.last_hit_damage = 30
	game.level_run.enemies[2] = Enemy{health = 1, alive = true, last_attack_serial = -1}

	testing.expect_value(t, damage_enemy(&game, 2, 1, 100), true)

	testing.expect_value(t, game.player.health, 60)
	testing.expect_value(t, game.player.last_hit_enemy, 1)
}

@(test)
test_first_book_death_respawns_at_checkpoint_and_tracks_damage :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	game.screen = Screen.LEVEL
	game.player.radius = config.radius
	game.player.health = 12
	game.player.grounded = false
	game.level_run.checkpoint_x = 400

	apply_player_hit(&game, 3, 5, -1, 100)
	game.player.invulnerability_time = 0
	apply_player_hit(&game, 3, 7, -1, 100)

	testing.expect_value(t, game.player.health, 60)
	testing.expect_value(t, game.screen, Screen.LEVEL)
	testing.expect_value(t, game.player.position.x, 400.0)
	testing.expect_value(t, game.level_run.damage_taken, 12)
	testing.expect_value(t, game.player.last_hit_enemy, -1)
}

@(test)
test_enemies_outside_camera_do_not_advance_their_ai :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	game.camera.target = {640, WINDOW_HEIGHT/2}
	initialize_level_run(&game)
	enemy := &game.level_run.enemies[7]
	enemy.aggressive = true
	before := enemy.position

	update_enemies(&game, 1.0)

	testing.expect_value(t, enemy.position.x, before.x)
	testing.expect_value(t, enemy.animation_time, 0.0)
}

@(test)
test_goblin_and_skeleton_patrol_while_mushroom_is_stationary :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	initialize_level_run(&game)
	game.level_run.enemies[1].patrol_pause = 0
	game.level_run.enemies[3].patrol_pause = 0

	mushroom_x := game.level_run.enemies[2].position.x
	goblin_x := game.level_run.enemies[1].position.x
	skeleton_x := game.level_run.enemies[3].position.x
	update_enemy_ai(&game, 2, 0.2)
	update_enemy_ai(&game, 1, 0.2)
	update_enemy_ai(&game, 3, 0.2)

	testing.expect_value(t, game.level_run.enemies[2].position.x, mushroom_x)
	testing.expect(t, game.level_run.enemies[1].position.x != goblin_x)
	testing.expect(t, game.level_run.enemies[3].position.x != skeleton_x)
}

@(test)
test_unseen_aggressive_enemy_waits_until_visible_to_pursue :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	game.camera.target = {640, WINDOW_HEIGHT/2}
	initialize_level_run(&game)
	enemy := &game.level_run.enemies[1]
	enemy.aggressive = true
	before := enemy.position.x
	game.player.position.x = before - 100

	update_enemy_ai(&game, 1, 0.5, false)

	testing.expect_value(t, enemy.position.x, before)
}

@(test)
test_mushroom_does_not_move_when_hit :: proc(t: ^testing.T) {
	config := load_player_config()
	catalog := load_creature_catalog()
	game := new_game({}, config, catalog)
	defer delete(game.world.rooms)
	defer delete(game.world.books)
	game.active_level = 0
	initialize_level_run(&game)
	mushroom := &game.level_run.enemies[2]
	before := mushroom.position.x

	testing.expect_value(t, damage_enemy(&game, 2, 1, 200), true)

	testing.expect_value(t, mushroom.knockback_x, 0.0)
	testing.expect_value(t, mushroom.position.x, before)
}

@(test)
test_library_room_loop :: proc(t: ^testing.T) {
    world := create_world()
    defer delete(world.rooms)
    defer delete(world.books)

    testing.expect_value(t, len(world.rooms), ROOM_COUNT)
    testing.expect_value(t, len(world.books), HALL_COUNT * BOOKS_PER_HALL)
    testing.expect_value(t, len(LEVELS), HALL_COUNT * BOOKS_PER_HALL)
    testing.expect_value(t, world.rooms[0].is_lobby, true)
    testing.expect_value(t, world.rooms[0].book_count, 0)

    room_index := 0
    for hall in 1..=HALL_COUNT {
        room_index = world.rooms[room_index].left_room
        testing.expect_value(t, room_index, hall)
    }
    testing.expect_value(t, world.rooms[room_index].left_room, 0)

    room_index = 0
    for hall in 1..=HALL_COUNT {
        room_index = world.rooms[room_index].right_room
        testing.expect_value(t, room_index, HALL_COUNT + 1 - hall)
    }
    testing.expect_value(t, world.rooms[room_index].right_room, 0)
}

@(test)
test_halls_have_three_floors_and_open_books :: proc(t: ^testing.T) {
    world := create_world()
    defer delete(world.rooms)
    defer delete(world.books)

    for hall in 0..<HALL_COUNT {
        room := world.rooms[hall + 1]
        testing.expect_value(t, room.floor_count, FLOOR_COUNT)
        testing.expect_value(t, room.book_count, BOOKS_PER_HALL)
        testing.expect(t, room.floor_y[0] > room.floor_y[1] && room.floor_y[1] > room.floor_y[2])

        for book_index in 0..<room.book_count {
            book := world.books[room.book_ids[book_index]]
            testing.expect_value(t, book.room_id, hall + 1)
            testing.expect_value(t, book.level_id, book.id)
            testing.expect_value(t, book.unlocked, true)
            if book.id % 2 == 0 {
                testing.expect_value(t, book.floor_index, 0)
            } else {
                testing.expect_value(t, book.floor_index, 1)
            }
        }

        for stair in room.stairs {
            testing.expect(t, stair.lower_x > 0 && stair.lower_x < WINDOW_WIDTH)
            testing.expect(t, stair.upper_x > 0 && stair.upper_x < WINDOW_WIDTH)
        }
    }
}
