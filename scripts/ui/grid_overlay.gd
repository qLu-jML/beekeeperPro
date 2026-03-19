extends Node2D

var show_grid: bool = false

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var player = get_node_or_null("../player")
    var tilemap: TileMap = get_node_or_null("../TileMap") as TileMap
    
    if not player or not tilemap:
        return
        
    var map_coords = player.get_target_tile_coords(tilemap) if player.has_method("get_target_tile_coords") else Vector2i.ZERO
    var snapped_rect = Rect2(tilemap.map_to_local(map_coords) - Vector2(8, 8), Vector2(16, 16))
    
    if show_grid:
        # Draw Targeter
        draw_rect(snapped_rect, Color(0, 1, 0, 0.3), true)
        draw_rect(snapped_rect, Color(0, 0, 0, 1.0), false, 1.5)
        
        # Draw Grid

        var start_x = int(player.global_position.x - 400) / 16 * 16
        var end_x = int(player.global_position.x + 400) / 16 * 16
        var start_y = int(player.global_position.y - 300) / 16 * 16
        var end_y = int(player.global_position.y + 300) / 16 * 16
        
        for x in range(start_x, end_x, 16):
            draw_line(Vector2(x, start_y), Vector2(x, end_y), Color(1, 1, 1, 0.2))
        for y in range(start_y, end_y, 16):
            draw_line(Vector2(start_x, y), Vector2(end_x, y), Color(1, 1, 1, 0.2))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_G:
            show_grid = not show_grid
