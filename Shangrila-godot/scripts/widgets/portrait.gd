class_name Portrait
extends Control
## Character portrait. 0 and 1 are the two painted portraits that survived ("The Man" and
## "The Enemy"); the rest are drawn procedurally to stand in for icons 301-347.

var index := 0:
	set(v):
		index = v
		queue_redraw()
var highlight := false:
	set(v):
		highlight = v
		queue_redraw()

const SKIN := [Color("#f0c8a0"), Color("#d8a878"), Color("#b07850"), Color("#7a5030"), Color("#e8d0b8"), Color("#c09070")]
const HAIR := [Color("#201810"), Color("#5a3a1a"), Color("#a06a30"), Color("#d8c070"), Color("#8a8a8a"), Color("#e8e8e8"), Color("#902818")]
const CLOTH := [Color("#6a2020"), Color("#20406a"), Color("#305a2a"), Color("#5a4a7a"), Color("#7a6a40"), Color("#404048"), Color("#8a5a20")]
const BG := [Color("#2a2018"), Color("#182028"), Color("#20281a"), Color("#281a28")]


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ell(c: Vector2, rx: float, ry: float, a0 := 0.0, a1 := TAU, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := a0 + (a1 - a0) * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("#120c08"))
	if index <= 1:
		var t := Ui.tex("The_Man" if index == 0 else "The_Enemy")
		# Crop the 140x113 paintings to a square around the face.
		var src := Rect2(22, 0, 100, 100) if index == 0 else Rect2(52, 2, 92, 92)
		draw_texture_rect_region(t, r, src)
	else:
		_draw_face()
	var edge := Color("#ff6040") if highlight else Color("#8a6a3a")
	draw_rect(r, edge, false, 2.0 if highlight else 1.0)


func _draw_face() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 7919 + 13
	var skin: Color = SKIN[rng.randi() % SKIN.size()]
	var hair: Color = HAIR[rng.randi() % HAIR.size()]
	var cloth: Color = CLOTH[rng.randi() % CLOTH.size()]
	var bg: Color = BG[rng.randi() % BG.size()]
	var hair_style := rng.randi() % 5     # 0 bald, 1 short, 2 long, 3 hood, 4 helmet
	var beard := rng.randi() % 3
	if hair_style >= 3:
		beard = rng.randi() % 2
	draw_set_transform(Vector2.ZERO, 0.0, size / 32.0)
	draw_rect(Rect2(0, 0, 32, 32), bg)
	if hair_style == 2:
		draw_colored_polygon(PackedVector2Array([Vector2(7, 10), Vector2(25, 10), Vector2(27, 27), Vector2(5, 27)]), hair)
	if hair_style == 3:
		draw_colored_polygon(_ell(Vector2(16, 15), 11, 12), cloth.darkened(0.2))
	# shoulders and neck
	draw_colored_polygon(_ell(Vector2(16, 33), 15, 8, PI, TAU), cloth)
	draw_rect(Rect2(13, 20, 6, 6), skin.darkened(0.15))
	# head
	draw_colored_polygon(_ell(Vector2(16, 14), 7, 8.5), skin)
	match hair_style:
		1:
			draw_colored_polygon(_ell(Vector2(16, 12), 7.5, 7, PI, TAU), hair)
		2:
			draw_colored_polygon(_ell(Vector2(16, 11.5), 7.8, 6.5, PI, TAU), hair)
		3:
			draw_colored_polygon(_ell(Vector2(16, 11), 9, 7, PI, TAU), cloth.darkened(0.2))
		4:
			draw_colored_polygon(_ell(Vector2(16, 12), 8.5, 8, PI, TAU), Color("#8a8f99"))
			draw_rect(Rect2(7.5, 11, 17, 2), Color("#6a6f79"))
			draw_rect(Rect2(15.2, 11, 1.6, 6), Color("#6a6f79"))
	# eyes, brows, mouth
	var eye_y := 14.0
	draw_circle(Vector2(13, eye_y), 1.0, Color("#101010"))
	draw_circle(Vector2(19, eye_y), 1.0, Color("#101010"))
	if hair_style != 4:
		draw_line(Vector2(11.5, eye_y - 2), Vector2(14.5, eye_y - 2.3), hair.darkened(0.2), 0.9)
		draw_line(Vector2(17.5, eye_y - 2.3), Vector2(20.5, eye_y - 2), hair.darkened(0.2), 0.9)
	draw_line(Vector2(16, 15), Vector2(15.4, 17.5), skin.darkened(0.3), 0.8)
	match beard:
		0:
			draw_line(Vector2(14, 19.5), Vector2(18, 19.5), Color("#803030"), 0.9)
		1:
			draw_colored_polygon(_ell(Vector2(16, 18), 6.5, 4.5, 0, PI), hair)
			draw_line(Vector2(14, 19), Vector2(18, 19), Color("#602020"), 0.8)
		2:
			draw_colored_polygon(PackedVector2Array([Vector2(10, 17), Vector2(22, 17), Vector2(19, 27), Vector2(16, 29), Vector2(13, 27)]), hair)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
