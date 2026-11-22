class_name StatusBars
extends Control
## The heart / apple / star bars (hits, health, magic) from DrawStatusBars.

var who: Dictionary = {}:
	set(v):
		who = v
		_update_tip()
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _update_tip() -> void:
	if who.is_empty():
		tooltip_text = ""
	else:
		tooltip_text = "Hits %d/%d\nHealth %d/%d\nMana %d/%d" % [who.hits, Game.full_hits(who), who.health, who.max_health, who.magic, who.max_magic]
		if who.get("wounded", false):
			tooltip_text += "\nBadly wounded: can't heal past %d hits until rested at the inn" % who.max_hits


func _bar(i: int, cur: int, mx: int, col: Color, cap := -1) -> void:
	var w := size.x / 3.0
	var r := Rect2(i * w + 2, 10, w - 6, size.y - 10)
	draw_rect(r, Color(0, 0, 0, 0.6))
	if cap >= 0 and mx > 0:
		# The part a bad wound keeps from healing: hatched across the top of the bar.
		var top := r.size.y * (1.0 - float(cap) / mx)
		var lr := Rect2(r.position, Vector2(r.size.x, top))
		draw_rect(lr, Color(0.35, 0.3, 0.28, 0.7))
		var bw := r.size.x
		var k := -bw
		while k < top:
			# The line y = k + bw - x across the block, clipped to it.
			var x0 := clampf(k + bw - top, 0.0, bw)
			var x1 := clampf(k + bw, 0.0, bw)
			if x1 > x0:
				draw_line(lr.position + Vector2(x0, k + bw - x0), lr.position + Vector2(x1, k + bw - x1), Color(0.12, 0.09, 0.08), 1.0)
			k += 4.0
	var f := 0.0 if mx <= 0 else clampf(float(cur) / mx, 0.0, 1.0)
	var fr := Rect2(r.position.x, r.end.y - r.size.y * f, r.size.x, r.size.y * f)
	draw_rect(fr, col)
	draw_rect(r, col.darkened(0.5), false, 1.0)
	_symbol(i, Vector2(r.position.x + r.size.x / 2.0, 4.5), col)


func _symbol(i: int, c: Vector2, col: Color) -> void:
	match i:
		0: # heart
			draw_circle(c + Vector2(-1.6, -0.5), 2.0, col)
			draw_circle(c + Vector2(1.6, -0.5), 2.0, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, 0), c + Vector2(3.5, 0), c + Vector2(0, 4)]), col)
		1: # apple
			draw_circle(c + Vector2(0, 0.5), 3.2, col)
			draw_line(c + Vector2(0, -2.5), c + Vector2(1, -4.5), Color("#6a4020"), 1)
		2: # star
			var pts := PackedVector2Array()
			for k in 10:
				var rad := 4.0 if k % 2 == 0 else 1.8
				pts.append(c + Vector2.from_angle(-PI / 2 + PI * k / 5.0) * rad)
			draw_colored_polygon(pts, col)


func _draw() -> void:
	if who.is_empty():
		return
	var wounded: bool = who.get("wounded", false)
	_bar(0, who.hits, Game.full_hits(who), Color("#d83020"), who.max_hits if wounded else -1)
	_bar(1, who.health, who.max_health, Color("#40b030"))
	_bar(2, who.magic, who.max_magic, Color("#4070e0"))
