class_name FigureArt
extends Control
## A standing figure for the walkable areas, drawn in code like RacePortrait: Human, Thuug,
## Aeldroe or Nisk. Drawn on a 64 x 128 grid and scaled to the control's size. Rendered into
## a texture (see FigureArt.texture_for) and shown as a flat cut-out that faces the viewer.
## `look`: skin, hair, cloth, legs, shell, and flags beard / hood / apron / hat.

const INK := Color("#1a1008")

var race := "Human"
var look := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A texture of the figure, rendered once in its own small viewport (kept under `owner_node`).
static func texture_for(owner_node: Node, race_: String, look_: Dictionary) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(128, 256)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var f := FigureArt.new()
	f.race = race_
	f.look = look_
	f.size = Vector2(128, 256)
	vp.add_child(f)
	owner_node.add_child(vp)
	return vp.get_texture()


func _c(key: String, fallback: String) -> Color:
	return Color(look.get(key, fallback))


func _ell(c: Vector2, rx: float, ry: float, a0 := 0.0, a1 := TAU, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := a0 + (a1 - a0) * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _poly(pts: Array, col: Color, outline := true) -> void:
	var p := PackedVector2Array(pts)
	draw_colored_polygon(p, col)
	if outline:
		draw_polyline(p + PackedVector2Array([p[0]]), INK, 1.0, true)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(64, 128))
	# A soft shadow at the feet.
	draw_colored_polygon(_ell(Vector2(32, 124), 18, 3.5), Color(0, 0, 0, 0.35))
	match race:
		"Thuug": _thuug()
		"Aeldroe": _aeldroe()
		"Nisk": _nisk()
		_: _human()


## Legs, body and arms of an upright figure. `top` is the shoulder line, `w` half its width.
func _body(top: float, w: float, cloth: Color, legs: Color, skin: Color, hip := 84.0, alpha := 1.0) -> void:
	var lc := Color(legs, alpha)
	_poly([Vector2(32 - w * 0.55, hip), Vector2(31, hip), Vector2(30, 120), Vector2(32 - w * 0.6, 120)], lc)
	_poly([Vector2(33, hip), Vector2(32 + w * 0.55, hip), Vector2(32 + w * 0.6, 120), Vector2(34, 120)], lc)
	var boot := Color("#3a2818", alpha)
	draw_rect(Rect2(32 - w * 0.7, 117, w * 0.62, 5), boot)
	draw_rect(Rect2(33, 117, w * 0.62, 5), boot)
	var cc := Color(cloth, alpha)
	_poly([Vector2(32 - w, top + 4), Vector2(32 - w + 4, top), Vector2(32 + w - 4, top), Vector2(32 + w, top + 4),
		Vector2(32 + w * 0.9, hip + 4), Vector2(32 - w * 0.9, hip + 4)], cc)
	draw_line(Vector2(32 - w * 0.9, hip - 2), Vector2(32 + w * 0.9, hip - 2), Color(cloth.darkened(0.45), alpha), 2.0)
	if look.get("apron", false):
		_poly([Vector2(32 - w * 0.6, top + 18), Vector2(32 + w * 0.6, top + 18), Vector2(32 + w * 0.7, hip + 10),
			Vector2(32 - w * 0.7, hip + 10)], Color("#d8ccb0", alpha))
	# Arms hanging at the sides, hands showing.
	var sc := Color(cloth.darkened(0.12), alpha)
	_poly([Vector2(32 - w, top + 4), Vector2(32 - w - 6, top + 34), Vector2(32 - w - 2, top + 36), Vector2(32 - w + 4, top + 10)], sc)
	_poly([Vector2(32 + w, top + 4), Vector2(32 + w + 6, top + 34), Vector2(32 + w + 2, top + 36), Vector2(32 + w - 4, top + 10)], sc)
	draw_circle(Vector2(32 - w - 4, top + 37), 3.2, Color(skin, alpha))
	draw_circle(Vector2(32 + w + 4, top + 37), 3.2, Color(skin, alpha))


func _human() -> void:
	var skin := _c("skin", "#d8a878")
	var hair := _c("hair", "#4a3018")
	var cloth := _c("cloth", "#6a4a2a")
	_body(36, 12, cloth, _c("legs", "#4a3a2a"), skin)
	if look.get("hood", false):
		draw_colored_polygon(_ell(Vector2(32, 22), 11, 13), cloth.darkened(0.15))
	draw_rect(Rect2(29, 30, 6, 7), skin.darkened(0.1))
	var face := _ell(Vector2(32, 22), 8, 10)
	draw_colored_polygon(face, skin)
	draw_polyline(face, INK, 1.0, true)
	draw_colored_polygon(_ell(Vector2(32, 19), 8.6, 8, PI, TAU), hair)
	if look.get("beard", false):
		draw_colored_polygon(_ell(Vector2(32, 26), 7, 7, 0, PI), hair)
	if look.get("hat", false):
		draw_colored_polygon(_ell(Vector2(32, 13), 13, 3), cloth.darkened(0.3))
		draw_rect(Rect2(25, 5, 14, 8), cloth.darkened(0.3))
	draw_circle(Vector2(29, 21), 1.0, INK)
	draw_circle(Vector2(35, 21), 1.0, INK)


func _thuug() -> void:
	var skin := _c("skin", "#6f8a5c")
	var shell := _c("shell", "#5a4630")
	# The shell behind a squat, broad body.
	var dome := _ell(Vector2(32, 64), 22, 30)
	draw_colored_polygon(dome, shell)
	for i in 3:
		draw_line(Vector2(16 + i * 16, 42), Vector2(18 + i * 14, 88), shell.darkened(0.35), 1.2)
	draw_polyline(dome, INK, 1.2, true)
	_body(46, 15, _c("cloth", "#8a7a5a"), skin.darkened(0.15), skin, 90)
	draw_rect(Rect2(26, 38, 12, 10), skin.darkened(0.1))
	var head := _ell(Vector2(32, 33), 12, 9)
	draw_colored_polygon(head, skin)
	draw_polyline(head, INK, 1.0, true)
	draw_circle(Vector2(25, 31), 1.6, Color("#2a1a08"))
	draw_circle(Vector2(39, 31), 1.6, Color("#2a1a08"))
	draw_polyline(PackedVector2Array([Vector2(27, 36), Vector2(32, 38), Vector2(37, 36)]), INK, 1.2, true)


func _aeldroe() -> void:
	var a := 0.62
	var skin := _c("skin", "#dce6f2")
	var hair := _c("hair", "#f0f4ff")
	draw_colored_polygon(_ell(Vector2(32, 30), 9, 20), Color(hair, a * 0.7))
	_body(32, 10, _c("cloth", "#4a4a8a"), _c("legs", "#3a3a6a"), skin, 80, a)
	draw_rect(Rect2(30, 26, 4, 7), Color(skin, a * 0.8))
	var face := _ell(Vector2(32, 18), 6.5, 10)
	draw_colored_polygon(face, Color(skin, a))
	draw_polyline(face, Color(1, 1, 1, 0.5), 1.0, true)
	draw_colored_polygon(_ell(Vector2(32, 13), 7, 6, PI, TAU), Color(hair, a))
	for dx in [-3.0, 3.0]:
		draw_colored_polygon(_ell(Vector2(32 + dx, 18), 1.8, 1.3), Color("#20284a"))


func _nisk() -> void:
	var fur := _c("skin", "#8a7866")
	var pink := Color("#d89a9a")
	# A long tail curling out behind.
	draw_polyline(PackedVector2Array([Vector2(40, 100), Vector2(50, 108), Vector2(56, 100), Vector2(58, 88)]), pink.darkened(0.2), 2.5, true)
	_body(56, 10, _c("cloth", "#5a4a3a"), _c("legs", "#3a3028"), fur, 96)
	for x in [24.0, 40.0]:
		draw_circle(Vector2(x, 36), 5.5, fur)
		draw_circle(Vector2(x, 36), 3.5, pink.darkened(0.1))
	var head := [Vector2(24, 42), Vector2(28, 36), Vector2(36, 36), Vector2(40, 42), Vector2(38, 50),
		Vector2(33, 57), Vector2(31, 57), Vector2(26, 50)]
	_poly(head, fur)
	draw_circle(Vector2(32, 56), 1.6, pink)
	draw_circle(Vector2(29, 44), 1.3, INK)
	draw_circle(Vector2(35, 44), 1.3, INK)
	for s in [-1.0, 1.0]:
		for k in 2:
			var o := Vector2(32 + s * 3, 54 + k * 1.5)
			draw_line(o, o + Vector2(s * 9, -2 + k * 3), Color("#e8e0d0"), 0.6, true)
