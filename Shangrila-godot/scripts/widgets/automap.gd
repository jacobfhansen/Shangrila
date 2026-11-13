class_name Automap
extends Control
## Map mode (DrawMap / PulsateLocation): every visited square of the 25x25 mines, with a
## pulsating marker for the party.

const N := 25
var pulse := 0.0


func _process(delta: float) -> void:
	if is_visible_in_tree():
		pulse += delta
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("#e2cc98"))
	draw_texture_rect(Ui.tex("parchment"), r, false, Color(1, 0.95, 0.85, 0.35))
	draw_rect(r, Color("#5a3a18"), false, 3)
	var cs := floorf((minf(size.x, size.y) - 30) / N)
	var o := (size - Vector2(cs * N, cs * N)) / 2.0 + Vector2(0, 8)
	var ink := Color(0.23, 0.14, 0.06)
	for y in range(1, N + 1):
		for x in range(1, N + 1):
			var cell := Vector2i(x, y)
			if not Game.visited.has(cell):
				continue
			var p := o + Vector2((x - 1) * cs, (y - 1) * cs)
			draw_rect(Rect2(p, Vector2(cs, cs)), Color(0.5, 0.33, 0.15, 0.55))
			var ex: Array = Game.mines.get(cell, [false, false, false, false])
			var corners := [p, p + Vector2(cs, 0), p + Vector2(cs, cs), p + Vector2(0, cs)]
			for d in 4:
				if not Game.exit_open(cell, d):
					draw_line(corners[d], corners[(d + 1) % 4], ink, 1.5)
	# party marker
	var c := o + Vector2((Game.pos.x - 0.5) * cs, (Game.pos.y - 0.5) * cs)
	var a := 0.55 + 0.45 * sin(pulse * 6.0)
	var dir := Vector2(Game.DIR_VEC[Game.facing])
	var side := Vector2(-dir.y, dir.x)
	var tri := PackedVector2Array([c + dir * cs * 0.45, c - dir * cs * 0.35 + side * cs * 0.35, c - dir * cs * 0.35 - side * cs * 0.35])
	draw_colored_polygon(tri, Color(0.1, 0.25, 0.9, a))
	var f := get_theme_default_font()
	draw_string(f, Vector2(0, 17), "The Mines", HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, ink)
