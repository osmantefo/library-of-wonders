package main

import rl "vendor:raylib"

Player :: struct {
    position: rl.Vector2,
    radius:   f32,
    speed:    f32,
}

update_player :: proc(player: ^Player, dt: f32) {
    direction := rl.Vector2{0, 0}

    if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)  { direction.x -= 1 }
    if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) { direction.x += 1 }
    if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)    { direction.y -= 1 }
    if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)  { direction.y += 1 }

    if direction.x != 0 || direction.y != 0 {
        direction = rl.Vector2Normalize(direction)
        player.position.x += direction.x * player.speed * dt
        player.position.y += direction.y * player.speed * dt
    }
}

render_player :: proc(player: Player) {
    rl.DrawCircleV(player.position, player.radius, COLOR_ACCENT)
    rl.DrawCircleLines(i32(player.position.x), i32(player.position.y), player.radius, rl.WHITE)
    rl.DrawCircleV({player.position.x - 4, player.position.y - 3}, 2, COLOR_BACKGROUND)
    rl.DrawCircleV({player.position.x + 4, player.position.y - 3}, 2, COLOR_BACKGROUND)
}