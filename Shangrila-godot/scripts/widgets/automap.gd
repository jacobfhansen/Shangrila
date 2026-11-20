class_name Automap
extends Control
## Map mode (DrawMap / PulsateLocation): every visited square of the current level of the mines
## (MinesArea), with a pulsating marker for the party. Things you have seen are marked with a symbol:
## a thing is seen once you have stood on its square or beside it, so niches with a chest, lever or
## lift (never stood on) are drawn closed, with their symbol, instead of looking like open passage.
## Under the map, a legend lists the symbols found so far on this level.

const WAY := Color(0.12, 0.25, 0.55)
const SAFE := Color(0.15, 0.42, 0.15)
const GOODS := Color(0.5, 0.3, 0.05)
const DANGER := Color(0.6, 0.1, 0.08)
const INK := Color(0.23, 0.14, 0.06)

## Symbol, legend text and colour for each mark, in legend order.
const MARKS := {
	"exit": ["☀", "Way out", WAY], "up": ["▲", "Way up", WAY], "down": ["▼", "Way down", WAY],
	"lift": ["L", "Lift", WAY], "camp": ["C", "Camp", SAFE], "npc": ["@", "Someone", SAFE],
	"chest": ["■", "Chest", GOODS], "chest_done": ["□", "Emptied chest", GOODS],
	"vein": ["◆", "Ore vein", GOODS], "lever": ["/", "Lever", INK], "note": ["§", "Writing", INK],
	"carving": ["○", "Carving", INK], "gate": ["▬", "Blocked way", DANGER],
	"trap": ["×", "Trap", DANGER], "breach": ["X", "The breach", DANGER], "warden": ["!", "Danger", DANGER],
}
const CARVED := ["tomb", "pillar", "words"]

var pulse := 0.0


func _process(delta: float) -> void:
	if is_visible_in_tree():
		pulse += delta
		queue_redraw()


## The mark for a thing, or "" for none.
static func _mark(lv: int, cell: Vector2i) -> String:
	var ch := MinesArea.char_at(lv, cell)
	var k := MinesArea.kind_of(lv, ch)
	var done := MinesArea.cleared(lv, ch, cell)
	match k:
		"exit", "up", "down", "lift", "camp", "lever", "note", "breach", "warden":
			return k
		"npc":
			return "" if done else "npc"
		"chest":
			return "chest_done" if done else "chest"
		"vein":
			return "" if done else "vein"
		"trap":
			return "trap" if done else ""
		"cart", "air", "door", "water", "ward":
			return "" if done else "gate"
	if k in CARVED:
		return "carving"
	return ""


## A square drawn as rock: rock itself, things set into the rock, and a secret not yet found.
static func _rock(lv: int, cell: Vector2i) -> bool:
	var ch := MinesArea.char_at(lv, cell)
	var k := MinesArea.kind_of(lv, ch)
	return ch == "#" or k in MinesArea.IN_ROCK or (k == "secret" and not MinesArea.cleared(lv, ch))


func _draw() -> void:
	var lv := Game.mine_level
	var map: Array = MinesArea.MAPS[lv - 1]
	var n := Vector2i(map[0].length(), map.size())
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("#e2cc98"))
	draw_texture_rect(Ui.tex("parchment"), r, false, Color(1, 0.95, 0.85, 0.35))
	draw_rect(r, Color("#5a3a18"), false, 3)
	var f := get_theme_default_font()

	# What has been seen: visited squares, and the things beside them.
	var seen := {}    # cell -> true: drawn as floor
	var marks := {}   # cell -> mark
	for y in n.y:
		for x in n.x:
			var cell := Vector2i(x, y)
			if not Game.visited.has(Vector3i(x, y, lv)):
				continue
			seen[cell] = true
			var m := _mark(lv, cell)
			if m != "":
				marks[cell] = m
			for d in 4:
				var nb: Vector2i = cell + Game.DIR_VEC[d]
				if nb.x < 0 or nb.y < 0 or nb.x >= n.x or nb.y >= n.y:
					continue
				var nm := _mark(lv, nb)
				if nm == "":
					continue
				marks[nb] = nm
				if not _rock(lv, nb):
					seen[nb] = true
	var found := []
	for k in MARKS:
		if k in marks.values():
			found.append(k)

	# Room for the legend under the map: three columns.
	var rows := ceili(found.size() / 3.0)
	var legend_h := rows * 13 + (6 if rows > 0 else 0)
	var cs := floorf(minf(size.x - 20, size.y - 34 - legend_h) / maxi(n.x, n.y))
	var o := Vector2((size.x - cs * n.x) / 2.0, 26)

	for cell: Vector2i in seen:
		var p := o + Vector2(cell.x * cs, cell.y * cs)
		draw_rect(Rect2(p, Vector2(cs, cs)), Color(0.5, 0.33, 0.15, 0.55))
		var corners := [p, p + Vector2(cs, 0), p + Vector2(cs, cs), p + Vector2(0, cs)]
		for d in 4:
			var nb: Vector2i = cell + Game.DIR_VEC[d]
			var closed := _rock(lv, nb) or (not Game.visited.has(Vector3i(cell.x, cell.y, lv))
				and not Game.visited.has(Vector3i(nb.x, nb.y, lv)) and not seen.has(nb))
			if closed:
				draw_line(corners[d], corners[(d + 1) % 4], INK, 1.5)
	for cell: Vector2i in marks:
		var mk: Array = MARKS[marks[cell]]
		var q := o + Vector2(cell.x * cs, cell.y * cs)
		draw_string(f, q + Vector2(0, cs - 1.5), mk[0], HORIZONTAL_ALIGNMENT_CENTER, cs, int(cs) - 1, mk[2])

	# Party marker.
	var c := o + Vector2((Game.pos.x + 0.5) * cs, (Game.pos.y + 0.5) * cs)
	var a := 0.55 + 0.45 * sin(pulse * 6.0)
	var dir := Vector2(Game.DIR_VEC[Game.facing])
	var side := Vector2(-dir.y, dir.x)
	var tri := PackedVector2Array([c + dir * cs * 0.45, c - dir * cs * 0.35 + side * cs * 0.35, c - dir * cs * 0.35 - side * cs * 0.35])
	draw_colored_polygon(tri, Color(0.1, 0.25, 0.9, a))
	draw_string(f, Vector2(0, 17), "The Mines, level %d: %s" % [lv, MinesArea.NAMES[lv - 1].to_lower()],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, INK)

	# Legend.
	var top := o.y + cs * n.y + 6
	var colw := (size.x - 16) / 3.0
	for i in found.size():
		var mk: Array = MARKS[found[i]]
		var at := Vector2(8 + (i % 3) * colw, top + (i / 3) * 13 + 10)
		draw_string(f, at, mk[0], HORIZONTAL_ALIGNMENT_CENTER, 12, 11, mk[2])
		draw_string(f, at + Vector2(14, 0), mk[1], HORIZONTAL_ALIGNMENT_LEFT, colw - 16, 10, INK)
