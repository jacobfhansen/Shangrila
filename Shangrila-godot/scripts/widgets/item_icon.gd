class_name ItemIcon
extends Control
## Draws an item icon procedurally. The original 32x32 PICT icons (400-430) did not survive,
## so every item gets a small vector drawing instead.

var item_id := 0:
	set(v):
		item_id = v
		queue_redraw()

const WOOD := Color("#7a5228")
const STEEL := Color("#c8ccd4")
const DARK := Color("#20140a")
const GOLDC := Color("#d4a830")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ell(c: Vector2, rx: float, ry: float, n := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _poly(pts: Array, col: Color, outline := true) -> void:
	var p := PackedVector2Array(pts)
	draw_colored_polygon(p, col)
	if outline:
		var o := p.duplicate()
		o.append(p[0])
		draw_polyline(o, col.darkened(0.55), 1.0, true)


func _draw() -> void:
	if item_id == 0:
		return
	var it := Game.item(item_id)
	if it.is_empty():
		return
	var c: Color = it.col
	draw_set_transform(Vector2.ZERO, 0.0, size / 32.0)
	match it.shape:
		"sword":
			_poly([Vector2(10, 21), Vector2(25, 5), Vector2(27, 7), Vector2(12, 23)], c)
			draw_line(Vector2(6, 18), Vector2(15, 27), GOLDC, 2.5)
			draw_line(Vector2(10, 22), Vector2(5, 27), WOOD, 3)
			draw_circle(Vector2(4.5, 27.5), 2, GOLDC)
		"knife":
			_poly([Vector2(13, 19), Vector2(25, 8), Vector2(24, 12), Vector2(15, 21)], c)
			draw_line(Vector2(14, 20), Vector2(7, 26), Color("#4a3020"), 4)
		"axe":
			draw_line(Vector2(9, 29), Vector2(20, 4), WOOD, 3)
			_poly([Vector2(17, 6), Vector2(27, 3), Vector2(29, 15), Vector2(19, 12)], c)
		"bardiche":
			draw_line(Vector2(5, 31), Vector2(23, 2), WOOD, 2.5)
			_poly([Vector2(19, 4), Vector2(27, 2), Vector2(29, 18), Vector2(22, 15), Vector2(20, 9)], c)
		"mace":
			draw_line(Vector2(7, 29), Vector2(18, 12), WOOD, 3)
			for a in 8:
				var d := Vector2.from_angle(TAU * a / 8.0)
				draw_line(Vector2(20, 10) + d * 5, Vector2(20, 10) + d * 8, c.darkened(0.2), 2)
			draw_circle(Vector2(20, 10), 6, c)
		"staff":
			draw_line(Vector2(7, 30), Vector2(24, 3), c, 3)
			draw_circle(Vector2(24.5, 3), 2.5, c.lightened(0.2))
		"bow":
			draw_arc(Vector2(4, 16), 14, -1.15, 1.15, 18, c, 2.5)
			var a := Vector2(4, 16) + Vector2.from_angle(-1.15) * 14
			var b := Vector2(4, 16) + Vector2.from_angle(1.15) * 14
			draw_line(a, b, Color("#e8e0c8"), 1)
		"quiver":
			_poly([Vector2(9, 10), Vector2(17, 6), Vector2(25, 24), Vector2(17, 28)], c)
			for i in 3:
				var base := Vector2(11 + i * 2.5, 9 - i * 1.2)
				draw_line(base, base + Vector2(-3, -6), Color("#e0d0b0"), 1)
				draw_line(base + Vector2(-3, -6), base + Vector2(-1, -7), Color("#c03020"), 2)
		"arrow":
			draw_line(Vector2(6, 26), Vector2(25, 7), c, 1.5)
			_poly([Vector2(27, 5), Vector2(21, 7), Vector2(25, 11)], STEEL)
			draw_line(Vector2(6, 26), Vector2(4, 22), Color("#c03020"), 2)
			draw_line(Vector2(6, 26), Vector2(10, 28), Color("#c03020"), 2)
		"helmet":
			var dome := [Vector2(5, 22)]
			for i in 13:
				dome.append(Vector2(16, 22) + Vector2.from_angle(PI + PI * i / 12.0) * 11)
			_poly(dome, c)
			draw_rect(Rect2(4, 21, 24, 4), c.darkened(0.25))
			draw_rect(Rect2(15, 12, 2.5, 15), c.darkened(0.35))
		"hat":
			_poly(_ell(Vector2(16, 25), 14, 3.5), c.darkened(0.2))
			_poly([Vector2(17, 2), Vector2(24, 25), Vector2(8, 25)], c)
			draw_circle(Vector2(15, 15), 1.5, GOLDC)
			draw_circle(Vector2(18, 20), 1, GOLDC)
		"shirt":
			_poly([Vector2(9, 6), Vector2(13, 4), Vector2(16, 7), Vector2(19, 4), Vector2(23, 6), Vector2(29, 12),
				Vector2(25, 16), Vector2(23, 13), Vector2(23, 28), Vector2(9, 28), Vector2(9, 13), Vector2(7, 16), Vector2(3, 12)], c)
		"robe":
			_poly([Vector2(11, 4), Vector2(16, 6), Vector2(21, 4), Vector2(28, 14), Vector2(25, 17), Vector2(22, 13),
				Vector2(27, 30), Vector2(5, 30), Vector2(10, 13), Vector2(7, 17), Vector2(4, 14)], c)
			draw_line(Vector2(9, 17), Vector2(23, 17), GOLDC, 1.5)
		"armor":
			_poly([Vector2(7, 6), Vector2(13, 4), Vector2(16, 8), Vector2(19, 4), Vector2(25, 6), Vector2(25, 27),
				Vector2(7, 27)], c)
			for y in [11, 16, 21]:
				for x in [11, 16, 21]:
					draw_circle(Vector2(x, y), 1, Color("#d8d0b0"))
		"pants":
			_poly([Vector2(9, 4), Vector2(23, 4), Vector2(25, 29), Vector2(18, 29), Vector2(16, 12), Vector2(14, 29), Vector2(7, 29)], c)
		"boots":
			_poly([Vector2(8, 3), Vector2(17, 3), Vector2(17, 19), Vector2(28, 22), Vector2(28, 28), Vector2(8, 28)], c)
			draw_rect(Rect2(8, 26, 20, 2.5), DARK)
		"sandals":
			_poly(_ell(Vector2(16, 20), 12, 5), c)
			draw_line(Vector2(8, 17), Vector2(14, 23), Color("#6a4020"), 2)
			draw_line(Vector2(16, 15), Vector2(20, 25), Color("#6a4020"), 2)
		"shoes":
			_poly([Vector2(4, 19), Vector2(14, 15), Vector2(20, 17), Vector2(28, 21), Vector2(28, 26), Vector2(4, 26)], c)
		"shield":
			_poly([Vector2(6, 5), Vector2(26, 5), Vector2(26, 15), Vector2(16, 29), Vector2(6, 15)], c)
			draw_line(Vector2(16, 6), Vector2(16, 27), STEEL.darkened(0.3), 2)
			draw_line(Vector2(7, 12), Vector2(25, 12), STEEL.darkened(0.3), 2)
		"sack":
			_poly([Vector2(11, 10), Vector2(21, 10), Vector2(27, 22), Vector2(23, 28), Vector2(9, 28), Vector2(5, 22)], c)
			_poly([Vector2(12, 4), Vector2(20, 4), Vector2(18, 10), Vector2(14, 10)], c.lightened(0.1))
			draw_line(Vector2(11, 10), Vector2(21, 10), Color("#4a3020"), 2)
		"book":
			draw_rect(Rect2(8, 5, 18, 23), Color("#f0e8d0"))
			draw_rect(Rect2(6, 4, 18, 23), c)
			draw_circle(Vector2(15, 15), 4, GOLDC)
			draw_circle(Vector2(15, 15), 2.5, c)
		"symbol":
			draw_arc(Vector2(16, 6), 9, 0.3, PI - 0.3, 14, Color("#b0b0b0"), 1)
			draw_rect(Rect2(14.5, 12, 3, 17), c)
			draw_rect(Rect2(10, 16, 12, 3), c)
		"flask":
			_poly(_ell(Vector2(16, 21), 8, 8), c)
			draw_rect(Rect2(13, 6, 6, 9), c.lightened(0.3))
			draw_rect(Rect2(12.5, 3, 7, 4), WOOD)
		"kit":
			draw_rect(Rect2(5, 9, 22, 17), c)
			draw_rect(Rect2(5, 9, 22, 17), c.darkened(0.5), false, 1)
			draw_rect(Rect2(14, 11, 4, 13), Color("#c02020"))
			draw_rect(Rect2(10, 15.5, 12, 4), Color("#c02020"))
		"lockpick":
			draw_rect(Rect2(4, 12, 24, 15), c)
			draw_circle(Vector2(11, 8), 4, STEEL)
			draw_circle(Vector2(11, 8), 2, c)
			draw_line(Vector2(15, 8), Vector2(26, 8), STEEL, 2)
			draw_line(Vector2(23, 8), Vector2(23, 11), STEEL, 2)
		"rope":
			for r in [11, 8, 5]:
				draw_arc(Vector2(16, 17), r, 0, TAU, 24, c, 2.5)
			draw_line(Vector2(27, 17), Vector2(29, 28), c, 2.5)
		"leaf":
			_poly([Vector2(5, 27), Vector2(10, 12), Vector2(20, 5), Vector2(28, 4), Vector2(26, 14), Vector2(19, 23)], c)
			draw_line(Vector2(5, 27), Vector2(24, 8), c.darkened(0.4), 1.2)
		"root":
			draw_polyline(PackedVector2Array([Vector2(14, 3), Vector2(17, 9), Vector2(13, 16), Vector2(17, 23), Vector2(14, 30)]), c, 3.5)
			draw_line(Vector2(15, 13), Vector2(8, 18), c, 2)
			draw_line(Vector2(16, 20), Vector2(23, 25), c, 2)
			draw_circle(Vector2(14, 4), 3, Color("#50a040"))
		"cheese":
			_poly([Vector2(4, 24), Vector2(26, 10), Vector2(29, 24)], c)
			_poly([Vector2(4, 24), Vector2(29, 24), Vector2(29, 28), Vector2(4, 28)], c.darkened(0.15))
			for h in [Vector2(20, 19), Vector2(25, 21), Vector2(15, 22)]:
				draw_circle(h, 1.4, c.darkened(0.35))
		"stonehead":
			_poly([Vector2(9, 12), Vector2(11, 7), Vector2(13, 10), Vector2(16, 5), Vector2(19, 10), Vector2(21, 7),
				Vector2(23, 12)], c.lightened(0.15))
			draw_colored_polygon(_ell(Vector2(16, 19), 8, 9), c)
			draw_line(Vector2(12, 18), Vector2(14.5, 18), c.darkened(0.45), 1.2)
			draw_line(Vector2(17.5, 18), Vector2(20, 18), c.darkened(0.45), 1.2)
			draw_line(Vector2(16, 19), Vector2(15.5, 23), c.darkened(0.35), 1.0)
			draw_line(Vector2(13.5, 25), Vector2(18.5, 25), c.darkened(0.45), 1.0)
			_poly([Vector2(10, 28), Vector2(22, 28), Vector2(21, 30), Vector2(11, 30)], c.darkened(0.25))
		_:
			draw_circle(Vector2(16, 16), 10, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
