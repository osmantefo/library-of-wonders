package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

MENU_TEXTURE_PATH :: "assets/texture/menu_screen.png"
PLAYER_IDLE_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Idle.png"
PLAYER_RUN_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Run.png"
PLAYER_JUMP_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Jump.png"
PLAYER_FALL_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Fall.png"
PLAYER_ATTACK_1_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Attack1.png"
PLAYER_ATTACK_2_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Attack2.png"
PLAYER_HIT_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Take Hit.png"
PLAYER_HIT_FLASH_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Take Hit - white silhouette.png"
PLAYER_DEATH_TEXTURE_PATH :: "assets/texture/player/player/Sprites/Death.png"
UI_FONT_PATH :: "assets/fonts/monogram/monogram/ttf/monogram-extended.ttf"
TITLE_FONT_PATH :: "assets/fonts/monogram/monogram/ttf/monogram-extended-italic.ttf"
GAME_MUSIC_PATH :: "assets/audio/top-down-fantasy-1.ogg"
CORRIDOR_ASSET_ROOT :: "assets/texture/Cold Corridors Files/Cold Corridors Files/Assets/Layers/"

Game_Assets :: struct {
	menu_background: rl.Texture2D,
	player_idle:     rl.Texture2D,
	player_run:      rl.Texture2D,
	player_jump:     rl.Texture2D,
	player_fall:     rl.Texture2D,
	player_attack_1: rl.Texture2D,
	player_attack_2: rl.Texture2D,
	player_hit:      rl.Texture2D,
	player_hit_flash: rl.Texture2D,
	player_death:    rl.Texture2D,
	corridor_back:   rl.Texture2D,
	corridor_far:    rl.Texture2D,
	corridor_middle: rl.Texture2D,
	corridor_near:   rl.Texture2D,
	corridor_foreground: rl.Texture2D,
	corridor_torch:  rl.Texture2D,
	creatures:       [CREATURE_COUNT]Creature_Assets,
	ui_font:         rl.Font,
	title_font:      rl.Font,
	render_target:   rl.RenderTexture2D,
	music:           rl.Music,
}

Creature_Assets :: struct {
	animation: rl.Texture2D,
	projectile: rl.Texture2D,
}

load_game_assets :: proc(config: Player_Config, creature_catalog: [CREATURE_COUNT]Creature_Config) -> Game_Assets {
	assets := Game_Assets{
		menu_background = rl.LoadTexture(cstring(MENU_TEXTURE_PATH)),
		player_idle = rl.LoadTexture(cstring(PLAYER_IDLE_TEXTURE_PATH)),
		player_run = rl.LoadTexture(cstring(PLAYER_RUN_TEXTURE_PATH)),
		player_jump = rl.LoadTexture(cstring(PLAYER_JUMP_TEXTURE_PATH)),
		player_fall = rl.LoadTexture(cstring(PLAYER_FALL_TEXTURE_PATH)),
		player_attack_1 = rl.LoadTexture(cstring(PLAYER_ATTACK_1_TEXTURE_PATH)),
		player_attack_2 = rl.LoadTexture(cstring(PLAYER_ATTACK_2_TEXTURE_PATH)),
		player_hit = rl.LoadTexture(cstring(PLAYER_HIT_TEXTURE_PATH)),
		player_hit_flash = rl.LoadTexture(cstring(PLAYER_HIT_FLASH_TEXTURE_PATH)),
		player_death = rl.LoadTexture(cstring(PLAYER_DEATH_TEXTURE_PATH)),
		corridor_back = rl.LoadTexture(cstring(CORRIDOR_ASSET_ROOT + "back.png")),
		corridor_far = rl.LoadTexture(cstring(CORRIDOR_ASSET_ROOT + "far.png")),
		corridor_middle = rl.LoadTexture(cstring(CORRIDOR_ASSET_ROOT + "middle.png")),
		corridor_near = rl.LoadTexture(cstring(CORRIDOR_ASSET_ROOT + "near.png")),
		corridor_foreground = rl.LoadTexture(cstring(CORRIDOR_ASSET_ROOT + "foreground.png")),
		corridor_torch = rl.LoadTexture(cstring("assets/texture/Cold Corridors Files/Cold Corridors Files/Assets/Torch/torch-sheet.png")),
		ui_font = rl.LoadFontEx(cstring(UI_FONT_PATH), 48, nil, 0),
		title_font = rl.LoadFontEx(cstring(TITLE_FONT_PATH), 48, nil, 0),
		render_target = rl.LoadRenderTexture(WINDOW_WIDTH, WINDOW_HEIGHT),
		music = rl.LoadMusicStream(cstring(GAME_MUSIC_PATH)),
	}

	if !rl.IsTextureValid(assets.menu_background) {
		panic("Could not load menu background: " + MENU_TEXTURE_PATH)
	}
	if !rl.IsTextureValid(assets.player_idle) {
		panic("Could not load idle player sprite: " + PLAYER_IDLE_TEXTURE_PATH)
	}
	if !rl.IsTextureValid(assets.player_run) {
		panic("Could not load running player sprite: " + PLAYER_RUN_TEXTURE_PATH)
	}
	if !rl.IsFontValid(assets.ui_font) {
		panic("Could not load UI font: " + UI_FONT_PATH)
	}
	if !rl.IsFontValid(assets.title_font) {
		panic("Could not load title font: " + TITLE_FONT_PATH)
	}
	if !rl.IsTextureValid(assets.render_target.texture) {
		panic("Could not create the fullscreen render target")
	}
	if !rl.IsMusicValid(assets.music) {
		panic("Could not load game music: " + GAME_MUSIC_PATH)
	}
	player_textures := [9]rl.Texture2D{
		assets.player_idle, assets.player_run, assets.player_jump, assets.player_fall,
		assets.player_attack_1, assets.player_attack_2, assets.player_hit,
		assets.player_hit_flash, assets.player_death,
	}
	for texture in player_textures {
		if !rl.IsTextureValid(texture) {
			panic("Could not load one of the player animation sheets from " + PLAYER_IDLE_TEXTURE_PATH)
		}
	}
	if !rl.IsTextureValid(assets.player_death) {
		panic("Could not load death animation: " + PLAYER_DEATH_TEXTURE_PATH)
	}
	corridor_textures := [6]rl.Texture2D{
		assets.corridor_back, assets.corridor_far, assets.corridor_middle,
		assets.corridor_near, assets.corridor_foreground, assets.corridor_torch,
	}
	for texture in corridor_textures {
		if !rl.IsTextureValid(texture) {
			panic("Could not load the Cold Corridors level assets")
		}
	}
	if assets.player_idle.width < i32(config.frame_width * config.idle_frame_count) ||
	   assets.player_run.width < i32(config.frame_width * config.run_frame_count) ||
		assets.player_idle.height < i32(config.frame_height) ||
		assets.player_run.height < i32(config.frame_height) {
		panic("Player sprite sheets do not match the frame dimensions in data/player.json")
	}
	player_animation_textures := [6]rl.Texture2D{
		assets.player_jump, assets.player_fall, assets.player_attack_1,
		assets.player_attack_2, assets.player_hit, assets.player_hit_flash,
	}
	player_animation_frames := [6]int{2, 2, config.attack_frame_count, config.attack_frame_count, 4, 4}
	for i in 0..<len(player_animation_textures) {
		if player_animation_textures[i].width < i32(config.frame_width * player_animation_frames[i]) ||
		   player_animation_textures[i].height < i32(config.frame_height) {
			panic("Player animation sheet dimensions do not match data/player.json")
		}
	}
	if assets.player_death.width < i32(config.frame_width * config.attack_frame_count) ||
	   assets.player_death.height < i32(config.frame_height) {
		panic("Player death animation sheet dimensions do not match data/player.json")
	}
	config_paths := CREATURE_CONFIG_PATHS
	for i in 0..<CREATURE_COUNT {
		sprite_path := strings.clone_to_cstring(creature_catalog[i].sprite_path, context.temp_allocator)
		projectile_path := strings.clone_to_cstring(creature_catalog[i].projectile_path, context.temp_allocator)
		assets.creatures[i] = Creature_Assets{
			animation = rl.LoadTexture(sprite_path),
			projectile = rl.LoadTexture(projectile_path),
		}
		if !rl.IsTextureValid(assets.creatures[i].animation) {
			fmt.panicf("Could not load creature animation: %s", creature_catalog[i].sprite_path)
		}
		if !rl.IsTextureValid(assets.creatures[i].projectile) {
			fmt.panicf("Could not load creature projectile: %s", creature_catalog[i].projectile_path)
		}
		if assets.creatures[i].animation.width < i32(creature_catalog[i].frame_width * creature_catalog[i].frame_count) ||
		   assets.creatures[i].animation.height < i32(creature_catalog[i].frame_height) ||
		   assets.creatures[i].projectile.width < i32(creature_catalog[i].projectile_frame_width * creature_catalog[i].projectile_frame_count) ||
		   assets.creatures[i].projectile.height < i32(creature_catalog[i].projectile_frame_height) {
			fmt.panicf("Creature sprite dimensions do not match %s", config_paths[i])
		}
	}

	assets.music.looping = true
	rl.SetMusicVolume(assets.music, 0.5)
	for texture in player_textures {
		rl.SetTextureFilter(texture, .POINT)
	}
	for creature in assets.creatures {
		rl.SetTextureFilter(creature.animation, .POINT)
		rl.SetTextureFilter(creature.projectile, .POINT)
	}
	for texture in corridor_textures {
		rl.SetTextureFilter(texture, .POINT)
	}
	rl.PlayMusicStream(assets.music)
	return assets
}

update_game_audio :: proc(assets: Game_Assets) {
	rl.UpdateMusicStream(assets.music)
}

unload_game_assets :: proc(assets: Game_Assets) {
	rl.UnloadTexture(assets.menu_background)
	rl.UnloadTexture(assets.player_idle)
	rl.UnloadTexture(assets.player_run)
	rl.UnloadTexture(assets.player_jump)
	rl.UnloadTexture(assets.player_fall)
	rl.UnloadTexture(assets.player_attack_1)
	rl.UnloadTexture(assets.player_attack_2)
	rl.UnloadTexture(assets.player_hit)
	rl.UnloadTexture(assets.player_hit_flash)
	rl.UnloadTexture(assets.player_death)
	rl.UnloadTexture(assets.corridor_back)
	rl.UnloadTexture(assets.corridor_far)
	rl.UnloadTexture(assets.corridor_middle)
	rl.UnloadTexture(assets.corridor_near)
	rl.UnloadTexture(assets.corridor_foreground)
	rl.UnloadTexture(assets.corridor_torch)
	for creature in assets.creatures {
		rl.UnloadTexture(creature.animation)
		rl.UnloadTexture(creature.projectile)
	}
	rl.UnloadFont(assets.ui_font)
	rl.UnloadFont(assets.title_font)
	rl.UnloadRenderTexture(assets.render_target)
	rl.UnloadMusicStream(assets.music)
}
