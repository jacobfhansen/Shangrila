class_name EnemyPanel
extends Control
## The encounter window drawn over the dungeon view. One row per monster group; while the
## player is choosing a target the rows can be clicked.

signal picked(group: int)

const ROW_H := 76

var combat: Combat
var targeting := false
var filter := Callable()   # gi -> bool, which groups may be targeted
var hovered := -1
var flash := {}            # gi -> seconds of red flash left


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	for k in flash.keys():
		flash[k] -= delta
		if flash[k] <= 0.0:
			flash.erase(k)
	queue_redraw()


func hit(gi: int) -> void:
	flash[gi] = 0.35


func _row(i: int) -> Rect2:
	return Rect2(6, 28 + i * ROW_H, size.x - 12, ROW_H - 6)


func _ok(gi: int) -> bool:
	return targeting and combat != null and not combat.living(gi).is_empty() \
		and (not filter.is_valid() or filter.call(gi))


func _gui_input(e: InputEvent) -> void:
	if combat == null:
		return
	if e is InputEventMouseMotion:
		hovered = -1
		for gi in combat.groups.size():
			if _row(gi).has_point(e.position) and _ok(gi):
				hovered = gi
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for gi in combat.groups.size():
			if _row(gi).has_point(e.position) and _ok(gi):
				accept_event()
				picked.emit(gi)
				return


func _draw() -> void:
	if combat == null:
		return
	var f := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	var head := "Round %d" % combat.round_no if combat.round_no > 0 else "Encounter!"
	draw_string(f, Vector2(0, 19), head, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Ui.GOLD)
	for gi in combat.groups.size():
		var g: Dictionary = combat.groups[gi]
		var r := _row(gi)
		var alive := combat.living(gi)
		var bg := Color(0.12, 0.08, 0.05, 0.9)
		if flash.has(gi):
			bg = bg.lerp(Color(0.7, 0.12, 0.05, 0.95), flash[gi] / 0.35)
		draw_rect(r, bg)
		var edge := Ui.EDGE
		if _ok(gi):
			edge = Color("#ffd870") if hovered == gi else Color("#c09040")
		draw_rect(r, edge, false, 2.0 if hovered == gi and _ok(gi) else 1.0)
		var box := Rect2(r.position + Vector2(4, 4), Vector2(r.size.y - 8, r.size.y - 8))
		draw_rect(box, Color(0.05, 0.03, 0.02))
		draw_monster(self, g.def, box, alive.is_empty())
		var tx := box.end.x + 8
		var title: String = combat.group_label(gi) if not alive.is_empty() else g.def.plural
		var col := Ui.TEXT if not alive.is_empty() else Ui.DIM
		draw_string(f, Vector2(tx, r.position.y + 20), title, HORIZONTAL_ALIGNMENT_LEFT, r.end.x - tx - 4, 14, col)
		if alive.is_empty():
			draw_string(f, Vector2(tx, r.position.y + 40), "defeated", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Ui.DIM)
			continue
		# one small health bar per monster
		var bx := tx
		var by := r.position.y + 32
		var asleep := 0
		for m in g.members:
			var bw := 26.0
			if bx + bw > r.end.x - 4:
				break
			draw_rect(Rect2(bx, by, bw, 6), Color(0, 0, 0, 0.8))
			if m.hp > 0:
				draw_rect(Rect2(bx, by, bw * float(m.hp) / m.max_hp, 6), Color("#c83020"))
				if m.sleep > 0:
					asleep += 1
			else:
				draw_line(Vector2(bx, by + 3), Vector2(bx + bw, by + 3), Ui.DIM, 1)
			bx += bw + 4
		var note := ""
		if g.def.get("undead", false):
			note = "undead"
		if asleep > 0:
			note = ("%d asleep" % asleep) + (", " + note if note != "" else "")
		if note != "":
			draw_string(f, Vector2(tx, r.position.y + 58), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#90b0e0"))


## Simple drawn monsters. "The Enemy" is the one monster painting that survived from 1997.
static func draw_monster(ci: CanvasItem, def: Dictionary, r: Rect2, dead: bool) -> void:
	var col := Color(def.col)
	if dead:
		col = Color(0.3, 0.28, 0.26)
	var eye := Color("#ff3020") if not dead else Color(0.2, 0.2, 0.2)
	var c := r.get_center()
	var s := r.size.x / 64.0
	match def.shape:
		"enemy":
			ci.draw_texture_rect_region(Ui.tex("The_Enemy"), r, Rect2(52, 2, 92, 92),
				Color(0.4, 0.4, 0.4) if dead else Color.WHITE)
		"rat":
			ci.draw_colored_polygon(_ell(c + Vector2(-2, 8) * s, 20 * s, 11 * s), col)
			ci.draw_colored_polygon(_ell(c + Vector2(17, 3) * s, 10 * s, 7 * s), col)
			ci.draw_circle(c + Vector2(14, -5) * s, 4 * s, col.lightened(0.2))
			ci.draw_circle(c + Vector2(21, 1) * s, 1.6 * s, eye)
			ci.draw_line(c + Vector2(-21, 10) * s, c + Vector2(-30, 2) * s, col.lightened(0.3), 2 * s)
			ci.draw_line(c + Vector2(-30, 2) * s, c + Vector2(-28, -10) * s, col.lightened(0.3), 1.5 * s)
		"bat":
			var w := PackedVector2Array([c, c + Vector2(-28, -14) * s, c + Vector2(-22, 2) * s, c + Vector2(-14, -2) * s,
				c + Vector2(-8, 8) * s])
			ci.draw_colored_polygon(w, col)
			var w2 := PackedVector2Array()
			for p in w:
				w2.append(Vector2(2 * c.x - p.x, p.y))
			w2.reverse()
			ci.draw_colored_polygon(w2, col)
			ci.draw_circle(c + Vector2(0, 2) * s, 7 * s, col.darkened(0.2))
			ci.draw_circle(c + Vector2(-3, 0) * s, 1.5 * s, eye)
			ci.draw_circle(c + Vector2(3, 0) * s, 1.5 * s, eye)
		"spider":
			for k in 4:
				for side in [-1, 1]:
					var a := Vector2(side * 6, -4 + k * 4) * s
					var knee := Vector2(side * (18 + k * 2), -14 + k * 8) * s
					var foot := Vector2(side * (26 + k), 6 + k * 6) * s
					ci.draw_polyline(PackedVector2Array([c + a, c + knee, c + foot]), col.lightened(0.15), 2 * s)
			ci.draw_colored_polygon(_ell(c + Vector2(0, 8) * s, 12 * s, 13 * s), col)
			ci.draw_colored_polygon(_ell(c + Vector2(0, -8) * s, 8 * s, 7 * s), col.lightened(0.1))
			for ex in [-4, -1.5, 1.5, 4]:
				ci.draw_circle(c + Vector2(ex, -10) * s, 1.2 * s, eye)
		"skeleton":
			var bone := col
			ci.draw_circle(c + Vector2(0, -16) * s, 9 * s, bone)
			ci.draw_circle(c + Vector2(-3.5, -17) * s, 2.4 * s, Color.BLACK)
			ci.draw_circle(c + Vector2(3.5, -17) * s, 2.4 * s, Color.BLACK)
			ci.draw_line(c + Vector2(0, -7) * s, c + Vector2(0, 16) * s, bone, 3 * s)
			for k in 4:
				var y := -2 + k * 4.5
				ci.draw_line(c + Vector2(-9 + k, y) * s, c + Vector2(9 - k, y) * s, bone, 2 * s)
			ci.draw_line(c + Vector2(-10, -4) * s, c + Vector2(-18, 12) * s, bone, 2 * s)
			ci.draw_line(c + Vector2(10, -4) * s, c + Vector2(20, -10) * s, bone, 2 * s)
			ci.draw_line(c + Vector2(20, -10) * s, c + Vector2(24, -26) * s, Color(0.6, 0.6, 0.65), 2.5 * s)
			ci.draw_line(c + Vector2(0, 16) * s, c + Vector2(-7, 30) * s, bone, 2.5 * s)
			ci.draw_line(c + Vector2(0, 16) * s, c + Vector2(7, 30) * s, bone, 2.5 * s)
		_:
			# kobold, goblin, orc: the same humanoid at different sizes
			var big := {"kobold": 0.75, "goblin": 0.9, "orc": 1.1}.get(def.shape, 1.0) as float
			var k := s * big
			var o := c + Vector2(0, 30 * s - 30 * k)
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-13, -2) * k, o + Vector2(13, -2) * k,
				o + Vector2(17, 28) * k, o + Vector2(-17, 28) * k]), col.darkened(0.35))
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-11, -16) * k, o + Vector2(-22, -24) * k,
				o + Vector2(-9, -10) * k]), col)
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(11, -16) * k, o + Vector2(22, -24) * k,
				o + Vector2(9, -10) * k]), col)
			ci.draw_colored_polygon(_ell(o + Vector2(0, -13) * k, 11 * k, 12 * k), col)
			ci.draw_circle(o + Vector2(-4, -15) * k, 2 * k, Color("#ffd040") if not dead else eye)
			ci.draw_circle(o + Vector2(4, -15) * k, 2 * k, Color("#ffd040") if not dead else eye)
			ci.draw_line(o + Vector2(-5, -6) * k, o + Vector2(5, -6) * k, Color.BLACK, 1.5 * k)
			if def.shape == "orc":
				ci.draw_line(o + Vector2(-4, -6) * k, o + Vector2(-4, -10) * k, Color.WHITE, 1.5 * k)
				ci.draw_line(o + Vector2(4, -6) * k, o + Vector2(4, -10) * k, Color.WHITE, 1.5 * k)
			ci.draw_line(o + Vector2(15, 4) * k, o + Vector2(24, -14) * k, Color(0.65, 0.65, 0.7), 2.5 * k)


static func _ell(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
