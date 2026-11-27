package main

import "core:encoding/json"
import "core:fmt"
import "core:os"

PLAYER_CONFIG_PATH :: "data/player.json"

Player_Config :: struct {
	move_speed:                 f32,
	radius:                     f32,
	frame_width:                int,
	frame_height:               int,
	idle_frame_count:           int,
	run_frame_count:            int,
	animation_frame_duration:   f32,
	render_scale:               f32,
	ground_anchor:              f32,
	jump_speed:                 f32,
	gravity:                    f32,
	coyote_time:                f32,
	jump_buffer_time:           f32,
	jump_cut_multiplier:        f32,
	attack_frame_count:         int,
	attack_frame_duration:      f32,
	attack_range:               f32,
	attack_cooldown:            f32,
	hit_knockback:              f32,
	max_health:                 int,
	siphon_fraction:            f32,
}

load_player_config :: proc() -> Player_Config {
	data, read_err := os.read_entire_file(PLAYER_CONFIG_PATH, context.temp_allocator)
	if read_err != nil {
		fmt.panicf("Could not read player configuration %q: %v", PLAYER_CONFIG_PATH, read_err)
	}

	config: Player_Config
	if unmarshal_err := json.unmarshal(data, &config, allocator=context.temp_allocator); unmarshal_err != nil {
		fmt.panicf("Could not parse player configuration %q: %v", PLAYER_CONFIG_PATH, unmarshal_err)
	}

	if config.move_speed <= 0 ||
		config.radius <= 0 ||
		config.frame_width <= 0 ||
		config.frame_height <= 0 ||
		config.idle_frame_count <= 0 ||
		config.run_frame_count <= 0 ||
		config.animation_frame_duration <= 0 ||
		config.render_scale <= 0 ||
		config.ground_anchor <= 0 ||
		config.ground_anchor > 1 ||
		config.jump_speed <= 0 ||
		config.gravity <= 0 ||
		config.coyote_time < 0 ||
		config.jump_buffer_time < 0 ||
		config.jump_cut_multiplier <= 0 ||
		config.jump_cut_multiplier >= 1 ||
		config.attack_frame_count <= 0 ||
		config.attack_frame_duration <= 0 ||
		config.attack_range <= 0 ||
		config.attack_cooldown <= 0 ||
		config.hit_knockback <= 0 ||
		config.max_health <= 0 ||
		config.siphon_fraction <= 0 ||
		config.siphon_fraction > 1 {
		fmt.panicf("Player configuration %q contains non-positive values", PLAYER_CONFIG_PATH)
	}

	return config
}
