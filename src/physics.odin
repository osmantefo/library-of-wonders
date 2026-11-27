package main

import rl "vendor:raylib"

resolve_room_bounds :: proc(player: ^Player, room: Room, floor_index: int) {
    player.position.x = clamp_f32(player.position.x, player.radius, WINDOW_WIDTH - player.radius)
    player.position.y = room.floor_y[floor_index] - player.radius
}

clamp_f32 :: proc(value, low, high: f32) -> f32 {
    if value < low { return low }
    if value > high { return high }
    return value
}

distance_squared :: proc(a, b: rl.Vector2) -> f32 {
    dx := a.x - b.x
    dy := a.y - b.y
    return dx*dx + dy*dy
}