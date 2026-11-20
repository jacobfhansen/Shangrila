class_name Automap
extends Control
## Map mode (DrawMap / PulsateLocation): every visited square of the current level of the mines
## (MinesArea), with a pulsating marker for the party. Lifts, ways up and down and camps are marked.

var pulse := 0.0


func _process(delta: float) -> void:
	if is_visible_in_tree():
		pulse += delta
		queue_redraw()


func _draw() -> void:
	var lv := Game.mine_level
	var map: Array = MinesArea.MAPS[lv - 1]
	var n := Vector2i(map[0].length(), map.size())
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("#e2cc98"))
	draw_texture_rect(Ui.tex("parchment"), r, false, Color(1, 0.95, 0.85, 0.35))
	draw_rect(r, Color("#5a3a18"), false, 3)
	var cs := floorf((minf(size.x, size.y) - 34) / maxi(n.x, n.y))
	var o := (size - Vector2(cs * n.x, cs * n.y)) / 2.0 + Vector2(0, 9)
	var ink := Color(0.23, 0.14, 0.06)
	var f := get_theme_default_font()
	for y in n.y:
		for x in n.x:
			var cell := Vector2i(x, y)
			if not Game.visited.has(Vector3i(x, y, lv)):
				continue
			var p := o + Vector2(x * cs, y * cs)
			draw_rect(Rect2(p, Vector2(cs, cs)), Color(0.5, 0.33, 0.15, 0.55))
			var corners := [p, p + Vector2(cs, 0), p + Vector2(cs, cs), p + Vector2(0, cs)]
			for d in 4:
				var nb: Vector2i = cell + Game.DIR_VEC[d]
				var ch := MinesArea.char_at(lv, nb)
				var k := MinesArea.kind_of(lv, ch)
				var wall := ch == "#" or k in MinesArea.IN_ROCK or (k == "secret" and not MinesArea.cleared(lv, ch))
				if wall:
					draw_line(corners[d], corners[(d + 1) % 4], ink, 1.5)
				else:
					var mark: String = {"down": "▼", "up": "▲", "lift": "L", "camp": "C", "exit": "☀"}.get(k, "")
					if mark != "" and not Game.visited.has(Vector3i(nb.x, nb.y, lv)):
						var q := o + Vector2(nb.x * cs, nb.y * cs)
						draw_string(f, q + Vector2(1, cs - 2), mark, HORIZONTAL_ALIGNMENT_CENTER, cs, int(cs) - 1, ink)
			var here: String = {"camp": "C"}.get(MinesArea.kind_of(lv, MinesArea.char_at(lv, cell)), "")
			if here != "":
				draw_string(f, p + Vector2(0, cs - 2), here, HORIZONTAL_ALIGNMENT_CENTER, cs, int(cs) - 1, ink)
	# party marker
	var c := o + Vector2((Game.pos.x + 0.5) * cs, (Game.pos.y + 0.5) * cs)
	var a := 0.55 + 0.45 * sin(pulse * 6.0)
	var dir := Vector2(Game.DIR_VEC[Game.facing])
	var side := Vector2(-dir.y, dir.x)
	var tri := PackedVector2Array([c + dir * cs * 0.45, c - dir * cs * 0.35 + side * cs * 0.35, c - dir * cs * 0.35 - side * cs * 0.35])
	draw_colored_polygon(tri, Color(0.1, 0.25, 0.9, a))
	draw_string(f, Vector2(0, 17), "The Mines, level %d: %s" % [lv, MinesArea.NAMES[lv - 1].to_lower()],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, ink)
