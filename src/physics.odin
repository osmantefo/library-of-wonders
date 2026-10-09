package main

import rl "vendor:raylib"

resolve_room_collisions :: proc(player: ^Player, room: Room) {
    bounds := room.bounds
    r := player.radius

    player.position.x = clamp_f32(player.position.x, bounds.x + r, bounds.x + bounds.width - r)
    player.position.y = clamp_f32(player.position.y, bounds.y + r, bounds.y + bounds.height - r)

    for obstacle in room.obstacles {
        if circle_rect_overlap(player.position, r, obstacle) {
            left   := player.position.x + r - obstacle.x
            right  := obstacle.x + obstacle.width - (player.position.x - r)
            top    := player.position.y + r - obstacle.y
            bottom := obstacle.y + obstacle.height - (player.position.y - r)
            min_x := min(left, right)
            min_y := min(top, bottom)
            if min_x < min_y {
                if left < right { player.position.x = obstacle.x - r }
                else            { player.position.x = obstacle.x + obstacle.width + r }
            } else {
                if top < bottom { player.position.y = obstacle.y - r }
                else             { player.position.y = obstacle.y + obstacle.height + r }
            }
        }
    }
}

circle_rect_overlap :: proc(center: rl.Vector2, radius: f32, rect: rl.Rectangle) -> bool {
    closest_x := clamp_f32(center.x, rect.x, rect.x + rect.width)
    closest_y := clamp_f32(center.y, rect.y, rect.y + rect.height)
    dx := center.x - closest_x
    dy := center.y - closest_y
    return dx*dx + dy*dy < radius*radius
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