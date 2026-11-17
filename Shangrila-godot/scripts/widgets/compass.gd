class_name Compass
extends Control
## The compass in the dungeon window (pictures 233-236). With `area` set it shows that area's
## facing instead of the party's in the mines.

var area: Object = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 2
	draw_circle(c, r, Color("#2a1c10"))
	draw_arc(c, r, 0, TAU, 48, Color("#d4a24a"), 2.5, true)
	draw_arc(c, r - 12, 0, TAU, 48, Color("#8a6a3a"), 1, true)
	var facing: int = area.facing if area else Game.facing
	var f := get_theme_default_font()
	for d in 4:
		var v := Vector2(Game.DIR_VEC[d])
		var col := Color("#ff6040") if d == facing else Color("#e8d8b0")
		var p := c + v * (r - 22)
		var letter: String = Game.DIR_LETTERS[d]
		var sz := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		draw_string(f, p + Vector2(-sz.x / 2.0, 5), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
	var dir := Vector2(Game.DIR_VEC[facing])
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([c + dir * (r - 34), c + side * 6, c - side * 6]), Color("#d83020"))
	draw_colored_polygon(PackedVector2Array([c - dir * (r - 34), c + side * 6, c - side * 6]), Color("#c8ccd4"))
	draw_circle(c, 3, Color("#d4a24a"))
