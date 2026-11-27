package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

MENU_TEXTURE_PATH :: "assets/texture/menu_screen.png"
PLAYER_ANIMATION_COUNT :: 13
Player_Animation :: enum {
	IDLE,
	RUN,
	JUMP,
	ATTACKS,
	AIR_ATTACK,
	CROUCH_ATTACK,
	CROUCH_IDLE,
	DEATH,
	HEALTH,
	HURT,
	PRAY,
	ROLL,
	SLIDE,
}
PLAYER_ANIMATION_PATHS :: [PLAYER_ANIMATION_COUNT]string{
	"assets/texture/player/knight/Idle.png",
	"assets/texture/player/knight/Run.png",
	"assets/texture/player/knight/Jump.png",
	"assets/texture/player/knight/Attacks.png",
	"assets/texture/player/knight/attack_from_air.png",
	"assets/texture/player/knight/crouch_attacks.png",
	"assets/texture/player/knight/crouch_idle.png",
	"assets/texture/player/knight/Death.png",
	"assets/texture/player/knight/Health.png",
	"assets/texture/player/knight/Hurt.png",
	"assets/texture/player/knight/Pray.png",
	"assets/texture/player/knight/Roll.png",
	"assets/texture/player/knight/Slide.png",
}
PLAYER_ANIMATION_COLUMNS :: [PLAYER_ANIMATION_COUNT]int{2, 2, 2, 8, 2, 2, 2, 2, 2, 2, 4, 2, 4}
PLAYER_ANIMATION_ROWS :: [PLAYER_ANIMATION_COUNT]int{4, 4, 4, 5, 4, 4, 4, 2, 4, 2, 3, 2, 3}
UI_FONT_PATH :: "assets/fonts/monogram/monogram/ttf/monogram-extended.ttf"
TITLE_FONT_PATH :: "assets/fonts/monogram/monogram/ttf/monogram-extended-italic.ttf"
GAME_MUSIC_PATH :: "assets/audio/top-down-fantasy-1.ogg"
CORRIDOR_ASSET_ROOT :: "assets/texture/Cold Corridors Files/Cold Corridors Files/Assets/Layers/"

Game_Assets :: struct {
	menu_background: rl.Texture2D,
	player_animations: [PLAYER_ANIMATION_COUNT]rl.Texture2D,
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
	animation_paths := PLAYER_ANIMATION_PATHS
	animation_columns := PLAYER_ANIMATION_COLUMNS
	animation_rows := PLAYER_ANIMATION_ROWS
	assets := Game_Assets{
		menu_background = rl.LoadTexture(cstring(MENU_TEXTURE_PATH)),
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
	for i in 0..<PLAYER_ANIMATION_COUNT {
		path := animation_paths[i]
		assets.player_animations[i] = rl.LoadTexture(strings.clone_to_cstring(path, context.temp_allocator))
		if !rl.IsTextureValid(assets.player_animations[i]) {
			fmt.panicf("Could not load player animation: %s", path)
		}
	}

	if !rl.IsTextureValid(assets.menu_background) {
		panic("Could not load menu background: " + MENU_TEXTURE_PATH)
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
	corridor_textures := [6]rl.Texture2D{
		assets.corridor_back, assets.corridor_far, assets.corridor_middle,
		assets.corridor_near, assets.corridor_foreground, assets.corridor_torch,
	}
	for texture in corridor_textures {
		if !rl.IsTextureValid(texture) {
			panic("Could not load the Cold Corridors level assets")
		}
	}
	for i in 0..<PLAYER_ANIMATION_COUNT {
		texture := assets.player_animations[i]
		if texture.width < i32(config.frame_width*animation_columns[i]) ||
		   texture.height < i32(config.frame_height*animation_rows[i]) {
			fmt.panicf("Player animation sheet dimensions do not match its 128x64 frame grid: %s", animation_paths[i])
		}
	}
	idle := assets.player_animations[int(Player_Animation.IDLE)]
	run := assets.player_animations[int(Player_Animation.RUN)]
	attacks := assets.player_animations[int(Player_Animation.ATTACKS)]
	idle_frame_total := (idle.width/i32(config.frame_width))*(idle.height/i32(config.frame_height))
	run_frame_total := (run.width/i32(config.frame_width))*(run.height/i32(config.frame_height))
	if idle_frame_total < i32(config.idle_frame_count) ||
	   run_frame_total < i32(config.run_frame_count) ||
	   attacks.width < i32(config.frame_width*config.attack_frame_count) ||
	   attacks.height < i32(config.frame_height*5) {
		panic("Player sprite sheets do not match the 128x64 knight animation layout")
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
	for texture in assets.player_animations {
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
	for texture in assets.player_animations {
		rl.UnloadTexture(texture)
	}
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
