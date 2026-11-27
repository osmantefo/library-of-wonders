package main

import "core:encoding/json"
import "core:fmt"
import "core:os"

CREATURE_COUNT :: 4

Creature_Type :: enum int {
	FLYING_EYE,
	GOBLIN,
	MUSHROOM,
	SKELETON,
}

CREATURE_CONFIG_PATHS :: [CREATURE_COUNT]string{
	"data/enemies/flying_eye.json",
	"data/enemies/goblin.json",
	"data/enemies/mushroom.json",
	"data/enemies/skeleton.json",
}

Creature_Config :: struct {
	name:                   string,
	sprite_path:            string,
	projectile_path:        string,
	frame_width:            int,
	frame_height:           int,
	frame_count:            int,
	projectile_frame_width: int,
	projectile_frame_height: int,
	projectile_frame_count: int,
	hits_to_kill:            int,
	move_speed:             f32,
	collision_width:        f32,
	collision_height:       f32,
	hover_height:           f32,
	attack_range:           f32,
	aggro_range:            f32,
	attack_damage:          int,
	projectile_damage:      int,
	projectile_speed:       f32,
	patrol_range:           f32,
	orbit_radius:           f32,
}

load_creature_catalog :: proc() -> [CREATURE_COUNT]Creature_Config {
	catalog: [CREATURE_COUNT]Creature_Config
	paths := CREATURE_CONFIG_PATHS
	for i in 0..<CREATURE_COUNT {
		path := paths[i]
		data, read_err := os.read_entire_file(path, context.temp_allocator)
		if read_err != nil {
			fmt.panicf("Could not read creature configuration %q: %v", path, read_err)
		}
		if unmarshal_err := json.unmarshal(data, &catalog[i], allocator=context.temp_allocator); unmarshal_err != nil {
			fmt.panicf("Could not parse creature configuration %q: %v", path, unmarshal_err)
		}
		config := catalog[i]
		if config.name == "" ||
		   config.sprite_path == "" ||
		   config.projectile_path == "" ||
		   config.frame_width <= 0 ||
		   config.frame_height <= 0 ||
		   config.frame_count <= 0 ||
		   config.projectile_frame_width <= 0 ||
		   config.projectile_frame_height <= 0 ||
		   config.projectile_frame_count <= 0 ||
		   config.hits_to_kill <= 0 ||
		   config.move_speed < 0 ||
		   config.collision_width <= 0 ||
		   config.collision_height <= 0 ||
		   config.hover_height < 0 ||
		   config.attack_range <= 0 ||
		   config.aggro_range <= 0 ||
		   config.attack_damage <= 0 ||
		   config.projectile_damage <= 0 ||
		   config.projectile_speed <= 0 ||
		   config.patrol_range < 0 ||
		   config.orbit_radius < 0 {
			fmt.panicf("Creature configuration %q contains invalid values", path)
		}
	}
	return catalog
}
