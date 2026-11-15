class_name RacePortrait
extends Control
## A simple drawn portrait for the four races (Human, Thuug, Aeldroe, Nisk).
## `look` holds colours: skin, hair, cloth, shell, and flags beard / hood.

var race := "Human":
	set(v):
		race = v
		queue_redraw()
var look := {}:
	set(v):
		look = v
		queue_redraw()
var dim := false:
	set(v):
		dim = v
		queue_redraw()
var highlight := false:
	set(v):
		highlight = v
		queue_redraw()

const INK := Color("#1a1008")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _c(key: String, fallback: String) -> Color:
	return Color(look.get(key, fallback))


func _ell(c: Vector2, rx: float, ry: float, a0 := 0.0, a1 := TAU, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := a0 + (a1 - a0) * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1c1610"))
	draw_set_transform(Vector2.ZERO, 0.0, size / 64.0)
	# A soft backdrop glow.
	draw_colored_polygon(_ell(Vector2(32, 26), 30, 26), Color("#2c2418"))
	match race:
		"Thuug": _thuug()
		"Aeldroe": _aeldroe()
		"Nisk": _nisk()
		_: _human()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if dim:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	var edge := Color("#e8c46a") if highlight else Color("#8a6a3a")
	draw_rect(Rect2(Vector2.ZERO, size), edge, false, 2.0 if highlight else 1.0)


func _shoulders(col: Color, wide := 26.0) -> void:
	var pts := _ell(Vector2(32, 66), wide, 18, PI, TAU)
	draw_colored_polygon(pts, col)
	draw_polyline(pts, INK, 1.0, true)


func _eyes(y: float, dx: float, r: float, col := INK) -> void:
	draw_circle(Vector2(32 - dx, y), r, col)
	draw_circle(Vector2(32 + dx, y), r, col)


func _human() -> void:
	var skin := _c("skin", "#d8a878")
	var hair := _c("hair", "#4a3018")
	_shoulders(_c("cloth", "#6a2a20"))
	if look.get("hood", false):
		draw_colored_polygon(_ell(Vector2(32, 30), 17, 20), _c("cloth", "#3a5a2a").darkened(0.15))
	draw_rect(Rect2(28, 40, 8, 10), skin.darkened(0.1))
	var face := _ell(Vector2(32, 30), 11, 14)
	draw_colored_polygon(face, skin)
	draw_polyline(face, INK, 1.0, true)
	# Hair cap.
	draw_colored_polygon(_ell(Vector2(32, 25), 12, 11, PI, TAU), hair)
	if look.get("beard", false):
		draw_colored_polygon(_ell(Vector2(32, 36), 10, 9, 0, PI), hair)
		draw_rect(Rect2(28, 37, 8, 2), skin.darkened(0.35))
	else:
		draw_line(Vector2(29, 38), Vector2(35, 38), skin.darkened(0.4), 1.2)
	_eyes(29, 4.5, 1.4)
	draw_line(Vector2(32, 30), Vector2(31, 34), skin.darkened(0.3), 1.0)


func _thuug() -> void:
	var skin := _c("skin", "#6f8a5c")
	var shell := _c("shell", "#5a4630")
	# The shell rises behind the shoulders.
	var dome := _ell(Vector2(32, 52), 30, 26, PI, TAU)
	draw_colored_polygon(dome, shell)
	for i in 4:
		var x := 10 + i * 14
		draw_line(Vector2(x, 36), Vector2(x + 4, 52), shell.darkened(0.35), 1.2)
	draw_polyline(dome, INK, 1.2, true)
	_shoulders(_c("cloth", "#d8c8a0"), 22)
	# A broad, flat head on a thick neck.
	draw_rect(Rect2(25, 38, 14, 12), skin.darkened(0.1))
	var head := _ell(Vector2(32, 31), 15, 11)
	draw_colored_polygon(head, skin)
	draw_polyline(head, INK, 1.0, true)
	# Eyes set wide, a beak-like mouth.
	_eyes(29, 9, 1.8, Color("#2a1a08"))
	_eyes(28.4, 9, 0.6, Color("#e8d890"))
	draw_polyline(PackedVector2Array([Vector2(25, 35), Vector2(32, 38), Vector2(39, 35)]), INK, 1.4, true)
	for p in [Vector2(26, 24), Vector2(35, 23), Vector2(30, 27)]:
		draw_circle(p, 1.2, skin.darkened(0.25))


func _aeldroe() -> void:
	# Half-transparent: everything is drawn with alpha, so the backdrop shows through.
	var a := 0.62
	var skin := _c("skin", "#dce6f2")
	var hair := _c("hair", "#f0f4ff")
	var cloth := _c("cloth", "#4a4a8a")
	draw_colored_polygon(_ell(Vector2(32, 34), 13, 24), Color(hair, a * 0.7))   # long hair behind
	_shoulders(Color(cloth, a), 20)
	draw_rect(Rect2(29, 40, 6, 10), Color(skin, a * 0.8))
	var face := _ell(Vector2(32, 28), 9, 15)
	draw_colored_polygon(face, Color(skin, a))
	draw_polyline(face, Color(1, 1, 1, 0.5), 1.0, true)
	draw_colored_polygon(_ell(Vector2(32, 20), 10, 8, PI, TAU), Color(hair, a))
	# Large, dark eyes.
	for dx in [-4.5, 4.5]:
		draw_colored_polygon(_ell(Vector2(32 + dx, 28), 2.6, 1.8), Color("#20284a"))
		draw_circle(Vector2(32 + dx + 0.6, 27.5), 0.6, Color(1, 1, 1, 0.8))
	draw_line(Vector2(30, 37), Vector2(34, 37), Color(skin.darkened(0.3), a), 1.0)
	# A faint shimmer.
	for i in 5:
		draw_circle(Vector2(14 + i * 9, 14 + (i % 2) * 30), 0.8, Color(1, 1, 1, 0.35))


func _nisk() -> void:
	var fur := _c("skin", "#8a7866")
	var pink := Color("#d89a9a")
	_shoulders(_c("cloth", "#3a3030"), 22)
	# Round ears.
	for x in [18.0, 46.0]:
		draw_circle(Vector2(x, 18), 8, fur)
		draw_circle(Vector2(x, 18), 5, pink.darkened(0.1))
		draw_arc(Vector2(x, 18), 8, 0, TAU, 24, INK, 1.0, true)
	# Head tapering into a snout.
	var head := PackedVector2Array([Vector2(20, 24), Vector2(26, 16), Vector2(38, 16), Vector2(44, 24),
		Vector2(42, 34), Vector2(35, 44), Vector2(32, 46), Vector2(29, 44), Vector2(22, 34)])
	draw_colored_polygon(head, fur)
	draw_polyline(head + PackedVector2Array([head[0]]), INK, 1.0, true)
	draw_colored_polygon(_ell(Vector2(32, 39), 6, 6), fur.lightened(0.15))
	draw_circle(Vector2(32, 44), 2.2, pink)
	_eyes(28, 5.5, 1.8)
	_eyes(27.4, 5.5, 0.5, Color(1, 1, 1, 0.9))
	# Whiskers.
	for s in [-1.0, 1.0]:
		for k in 3:
			var o := Vector2(32 + s * 4, 42 + k * 1.5)
			draw_line(o, o + Vector2(s * 15, -3 + k * 3), Color("#e8e0d0"), 0.6, true)
