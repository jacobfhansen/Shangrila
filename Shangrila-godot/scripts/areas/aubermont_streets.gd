class_name AubermontStreets
extends RefCounted
## Aubermont's river gate district, walked in first person (shown by DungeonView, like Lehan's
## streets): narrow streets of tall, soot-black houses whose upper storeys jut out further with
## every floor, so they lean over the street and nearly meet overhead; a small market square with
## the Founders' statue; wet cobbles, lanterns, a low grey sky. See "The story onward" in IDEAS.md.
##
## The map, north at the top:
##   .  cobbles          #  a house
##   G  the river gate (back to the world map)     I  the Lamplighter inn     S  Corvin's shop
##   O  the arch to the old town (west)            H  the gate up to the hill (north)
##   F  the Founders' statue and fountain          L  a lamp post
##   s  a stall          B  barrels
##   1-9  people (AubermontData.PEOPLE)
## Houses, doors and props block the way; walking into a door or a person uses it.

const MAP := [
	"######################",
	"##########H###########",
	"##########.###########",
	"#########2.###########",
	"######s.......s#######",
	"######L...3...L#######",
	"O.........F.........I#",
	"######.....4...###5.##",
	"######s.1......S######",
	"######B......B.#######",
	"##########.###########",
	"##########.###########",
	"#######....###########",
	"#######.##############",
	"#######.##############",
	"#######.##############",
	"#######G##############",
	"######################",
]
const CELL := DungeonView.CELL
const GROUND := 2.3      # the stone ground floor
const UPPER := 1.9       # each storey above it
const JUT := 0.26        # how much further out each storey sits than the one below...
const MAX_JUT := 0.78    # ... up to this, so across a narrow street the eaves nearly meet
const BUILDING := "#IGSOH"
const EXITS := {"G": "gate", "I": "inn", "S": "shop", "O": "oldtown", "H": "hill"}
const ENTRANCES := {
	"gate": {"cell": Vector2i(7, 15), "dir": 2},
	"inn": {"cell": Vector2i(19, 6), "dir": 1},
	"shop": {"cell": Vector2i(14, 8), "dir": 1},
	"oldtown": {"cell": Vector2i(1, 6), "dir": 3},
	"hill": {"cell": Vector2i(10, 2), "dir": 0},
}

var pos: Vector2i = ENTRANCES.gate.cell
var facing := 0
var eye := 1.3


func _char(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= MAP.size() or cell.x < 0 or cell.x >= MAP[cell.y].length():
		return "#"
	return MAP[cell.y][cell.x]


## Stand at a place's entrance: facing its door (`into`), or with the back to it (just came out).
func place_at(place: String, into: bool) -> void:
	var e: Dictionary = ENTRANCES.get(place, ENTRANCES.gate)
	pos = e.cell
	facing = e.dir if into else (e.dir + 2) % 4


func size() -> Vector2i:
	return Vector2i(MAP[0].length(), MAP.size())


func is_open(cell: Vector2i) -> bool:
	return _char(cell) == "."


func can_move(from: Vector2i, dir: int) -> bool:
	return _char(from + Game.DIR_VEC[dir]) == "."


## What is in a cell: {"kind": "person", "id"} / {"kind": "exit", "to"} / {"kind": "prop", "what"}
## / {"kind": "wall"} / {} for open cobbles.
func thing_at(cell: Vector2i) -> Dictionary:
	var ch := _char(cell)
	if ch == ".":
		return {}
	if EXITS.has(ch):
		return {"kind": "exit", "to": EXITS[ch]}
	if AubermontData.PEOPLE.has(ch):
		return {"kind": "person", "id": ch}
	if ch == "#":
		return {"kind": "wall"}
	return {"kind": "prop", "what": {"F": "founders", "L": "lamp", "s": "stall", "B": "barrels"}.get(ch, "")}


func ahead() -> Vector2i:
	return pos + Game.DIR_VEC[facing]


## How many storeys a house has (3 to 5), fixed for each square of the map.
func _storeys(cell: Vector2i) -> int:
	return 3 + absi(cell.x * 73 + cell.y * 151 + cell.x * cell.y * 7) % 3


func _hash(cell: Vector2i) -> int:
	return absi(cell.x * 7919 + cell.y * 104729)


## How far out the face of a storey sits at height `y` (0 at the ground floor's face).
func _jut_at(k: int) -> float:
	return minf(JUT * k, MAX_JUT)


## The top of a house: ground floor plus its upper storeys.
func _top(n: int) -> float:
	return GROUND + UPPER * (n - 1)


# ---------------------------------------------------------------- building the scene

func build(root: Node3D, cam: Camera3D) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#2a3038")
	sm.sky_horizon_color = Color("#5c6066")
	sm.ground_horizon_color = Color("#3a3c40")
	sm.ground_bottom_color = Color("#1a1a1c")
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.56)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true   # the smoke of ten thousand chimneys
	env.fog_light_color = Color(0.3, 0.32, 0.35)
	env.fog_density = 0.035
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.8, 0.85, 0.95)
	sun.light_energy = 0.35
	sun.rotation = Vector3(deg_to_rad(-60), deg_to_rad(20), 0)
	root.add_child(sun)
	cam.fov = 75

	var floors := _st()
	var by_tex := {}   # texture name -> SurfaceTool
	var roofs := _st()
	var lanterns := []   # wall lanterns: [position, out of the wall]
	var spires := []     # [position, height]
	var h := CELL / 2.0
	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			if BUILDING.contains(_char(cell)):
				continue
			var c := Vector3(x * CELL, 0, y * CELL)
			_quad(floors, c, Vector3.UP, Vector3.FORWARD, h, h)
			for d in 4:
				var n: Vector2i = cell + Game.DIR_VEC[d]
				var ch := _char(n)
				if not BUILDING.contains(ch):
					continue
				var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)   # from the street into the house
				var out := -dv
				var wall_c := c + dv * h
				var variant := _hash(n) % 4
				var low := "aub_low_%d" % variant
				match ch:
					"G": low = "aub_gate"
					"I": low = "aub_inn"
					"S": low = "aub_shop"
					"O": low = "aub_arch"
					"H": low = "aub_hill_gate"
				var side := Vector3.UP.cross(out)
				var side_g := Vector2i(roundi(side.x), roundi(side.z))
				var kl := _corner(n, cell, -side_g)
				var kr := _corner(n, cell, side_g)
				var storeys := _storeys(n)
				# The ground floor, flat against the street.
				_tool(by_tex, low)
				_band(by_tex[low], wall_c, out, side, 0.0, GROUND, 0.0, 0.0, h, kl, kr)
				# The upper storeys, each further out than the last and leaning outward as it rises.
				for k in range(1, storeys):
					var up := "aub_up_%d" % ((variant + k) % 4)
					_tool(by_tex, up)
					var y0 := GROUND + UPPER * (k - 1)
					_band(by_tex[up], wall_c, out, side, y0, y0 + UPPER, _jut_at(k), _jut_at(k + 1) if k + 1 < storeys else _jut_at(k) + 0.06, h, kl, kr)
				# The underside of the first overhang, over the ground floor.
				_tool(by_tex, "aub_side")
				_flat(by_tex["aub_side"], wall_c, out, side, GROUND, 0.0, _jut_at(1), h, kl, kr)
				# A steep slate roof from the eaves back to a high ridge.
				var top := _top(storeys)
				var o_top := _jut_at(storeys - 1) + 0.06
				var eave_out := o_top + 0.25
				var depth := 1.3
				var eave := wall_c + out * eave_out + Vector3(0, top, 0)
				var ridge := wall_c - out * depth + Vector3(0, top + 2.6, 0)
				_slope(roofs, eave, ridge, dv, h + kl * eave_out, h + kr * eave_out, h - kl * depth, h - kr * depth)
				# Where a taller house stands beside a lower one along the street, close its side.
				for e in [-1, 1]:
					var m: Vector2i = n + side_g * int(e)
					var ke := kl if e < 0 else kr
					if ke != 0 or not BUILDING.contains(_char(m)):
						continue
					var lower := _storeys(m)
					if lower >= storeys:
						continue
					var y_lo := _top(lower)
					var bnd: Vector3 = wall_c + side * (h * e)
					var reach := o_top + 0.3
					_quad(by_tex["aub_side"], bnd + out * (reach - depth) / 2.0 + Vector3(0, (y_lo + top + 2.6) / 2.0, 0),
						side * e, Vector3.UP, (reach + depth) / 2.0, (top + 2.6 - y_lo) / 2.0)
				# A spire on some outside corners, and a lantern on some walls.
				var hs := _hash(n)
				if (kl == 1 or kr == 1) and hs % 3 == 0:
					var e2 := -1 if kl == 1 else 1
					spires.append([wall_c + side * (h * e2) + out * (o_top - 0.2) + Vector3(0, top, 0), 3.0 + float(hs % 5) * 0.5])
				if hs % 4 == 1 and ch == "#":
					lanterns.append([wall_c + out * 0.18 + Vector3(0, GROUND - 0.35, 0), out])
	var cob := _mat("aub_cobbles", Color(0.9, 0.9, 0.95), 2.0)
	cob.roughness = 0.35   # wet
	cob.metallic_specular = 0.7
	_add(root, floors, cob)
	for t in by_tex:
		var m := _mat(t, Color.WHITE)
		if t.begins_with("aub_up_") or t == "aub_inn":
			m.emission_enabled = true
			m.emission = Color(1.0, 0.72, 0.4)
			m.emission_energy_multiplier = 1.4
			m.emission_texture = Ui.tex(t + "_glow")
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY   # only the lit windows glow
		_add(root, by_tex[t], m)
	_add(root, roofs, _mat("aub_slate", Color(0.9, 0.9, 0.95)))
	var slate := _mat("aub_slate", Color(0.8, 0.8, 0.85))
	for sp in spires:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.5
		cm.height = sp[1]
		cm.radial_segments = 8
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = slate
		mi.position = sp[0] + Vector3(0, sp[1] / 2.0, 0)
		root.add_child(mi)
	var lit := 0
	for ln in lanterns:
		_lantern(root, ln[0], ln[1], lit < 8)
		lit += 1

	for y in MAP.size():
		for x in MAP[y].length():
			var at := Vector3(x * CELL, 0, y * CELL)
			match MAP[y][x]:
				"F": _founders(root, at)
				"L": _lamp_post(root, at)
				"s": _stall(root, at)
				"B": _barrels(root, at)
				var ch:
					if AubermontData.PEOPLE.has(ch):
						_person(root, at, AubermontData.PEOPLE[ch])


## 1 if house `n`'s wall (seen from open `cell`) ends at an outside corner on side `e`, -1 at an
## inside corner, 0 if it runs straight on.
func _corner(n: Vector2i, cell: Vector2i, e: Vector2i) -> int:
	if not BUILDING.contains(_char(n + e)):
		return 1
	if BUILDING.contains(_char(cell + e)):
		return -1
	return 0


## A storey's face: from height y0 to y1, `o0` out from the wall line at the bottom and `o1` at the
## top (leaning out when o1 > o0). At corners it reaches further (outside) or less far (inside) by
## its jut, so neighbouring faces meet.
func _band(st: SurfaceTool, wall_c: Vector3, out: Vector3, side: Vector3, y0: float, y1: float, o0: float, o1: float,
		h: float, kl: int, kr: int) -> void:
	var bl := wall_c + out * o0 - side * (h + kl * o0) + Vector3(0, y0, 0)
	var br := wall_c + out * o0 + side * (h + kr * o0) + Vector3(0, y0, 0)
	var tl := wall_c + out * o1 - side * (h + kl * o1) + Vector3(0, y1, 0)
	var tr := wall_c + out * o1 + side * (h + kr * o1) + Vector3(0, y1, 0)
	var n := (tr - tl).cross(bl - tl).normalized()
	if n.dot(out) < 0:
		n = -n
	for v in [[tl, Vector2(0, 0)], [tr, Vector2(1, 0)], [br, Vector2(1, 1)], [tl, Vector2(0, 0)], [br, Vector2(1, 1)], [bl, Vector2(0, 1)]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


## A flat underside at height y, from o0 to o1 out from the wall line.
func _flat(st: SurfaceTool, wall_c: Vector3, out: Vector3, side: Vector3, y: float, o0: float, o1: float,
		h: float, kl: int, kr: int) -> void:
	var a := wall_c + out * o0 - side * (h + kl * o0) + Vector3(0, y, 0)
	var b := wall_c + out * o0 + side * (h + kr * o0) + Vector3(0, y, 0)
	var c := wall_c + out * o1 + side * (h + kr * o1) + Vector3(0, y, 0)
	var d := wall_c + out * o1 - side * (h + kl * o1) + Vector3(0, y, 0)
	for v in [[a, Vector2(0, 0)], [b, Vector2(1, 0)], [c, Vector2(1, 0.2)], [a, Vector2(0, 0)], [c, Vector2(1, 0.2)], [d, Vector2(0, 0.2)]]:
		st.set_normal(Vector3.DOWN)
		st.set_uv(v[1])
		st.add_vertex(v[0])


func _lantern(root: Node3D, at: Vector3, out: Vector3, with_light: bool) -> void:
	var iron := _plain(Color(0.1, 0.1, 0.1))
	_box(root, at - out * 0.12 + Vector3(0, 0.25, 0), Vector3(0.05, 0.05, 0.05) + out.abs() * 0.25, iron)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(1.0, 0.75, 0.4)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.62, 0.25)
	glass.emission_energy_multiplier = 1.2
	_box(root, at, Vector3(0.18, 0.28, 0.18), glass)
	_box(root, at + Vector3(0, 0.17, 0), Vector3(0.24, 0.05, 0.24), iron)
	if with_light:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 1.4
		l.omni_range = 5.0
		l.position = at + out * 0.3
		root.add_child(l)


func _lamp_post(root: Node3D, at: Vector3) -> void:
	var iron := _plain(Color(0.08, 0.08, 0.09))
	_cyl(root, at + Vector3(0, 1.4, 0), 0.06, 2.8, iron)
	_cyl(root, at + Vector3(0, 0.1, 0), 0.16, 0.2, iron)
	_lantern(root, at + Vector3(0, 2.95, 0), Vector3.BACK, true)


## The Founders: five lords in stone on a plinth in a dry fountain, swords point-down, standing
## round a broken crown at their feet.
func _founders(root: Node3D, at: Vector3) -> void:
	var stone := _mat("aub_side", Color(0.85, 0.85, 0.88))
	_cyl(root, at + Vector3(0, 0.2, 0), 0.95, 0.4, stone)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.1, 0.12, 0.14)
	water.roughness = 0.05
	_cyl(root, at + Vector3(0, 0.36, 0), 0.82, 0.04, water)
	_cyl(root, at + Vector3(0, 0.75, 0), 0.45, 0.8, stone)
	for i in 5:
		var a := i * TAU / 5.0
		var p := at + Vector3(cos(a) * 0.3, 1.15, sin(a) * 0.3)
		_cyl(root, p + Vector3(0, 0.45, 0), 0.09, 0.9, stone)
		var head := SphereMesh.new()
		head.radius = 0.08
		head.height = 0.16
		var mi := MeshInstance3D.new()
		mi.mesh = head
		mi.material_override = stone
		mi.position = p + Vector3(0, 0.98, 0)
		root.add_child(mi)
		_box(root, p + Vector3(cos(a) * 0.12, 0.35, sin(a) * 0.12), Vector3(0.03, 0.7, 0.03), stone)
	# The broken crown: a ring of points, two pieces apart.
	for i in 7:
		var a := i * TAU / 9.0
		_box(root, at + Vector3(cos(a) * 0.14, 1.2, sin(a) * 0.14), Vector3(0.04, 0.1, 0.04), stone, Vector3(0, -a, 0.3))


func _stall(root: Node3D, at: Vector3) -> void:
	var wood := _plain(Color(0.2, 0.15, 0.12))
	_box(root, at + Vector3(0, 0.45, 0), Vector3(1.4, 0.9, 0.8), wood)
	var cloth := _plain(Color(0.25, 0.18, 0.2))
	for sx in [-0.65, 0.65]:
		_box(root, at + Vector3(sx, 1.1, 0.35), Vector3(0.05, 2.2, 0.05), wood)
	_box(root, at + Vector3(0, 2.1, 0.1), Vector3(1.6, 0.05, 1.1), cloth, Vector3(0.25, 0, 0))


func _barrels(root: Node3D, at: Vector3) -> void:
	var wood := _plain(Color(0.22, 0.16, 0.12))
	for p in [Vector3(-0.35, 0.45, 0.2), Vector3(0.4, 0.45, -0.1), Vector3(0.0, 0.45, -0.5)]:
		_cyl(root, at + p, 0.32, 0.9, wood)


# ---------------------------------------------------------------- mesh helpers

func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _tool(d: Dictionary, key: String) -> void:
	if not d.has(key):
		d[key] = _st()


func _quad(st: SurfaceTool, c: Vector3, n: Vector3, u: Vector3, hw: float, hh: float) -> void:
	var r := u.cross(n)
	var tl := c - r * hw + u * hh
	var tr := c + r * hw + u * hh
	var br := c + r * hw - u * hh
	var bl := c - r * hw - u * hh
	for v in [[tl, Vector2(0, 0)], [tr, Vector2(1, 0)], [br, Vector2(1, 1)], [tl, Vector2(0, 0)], [br, Vector2(1, 1)], [bl, Vector2(0, 1)]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


func _slope(st: SurfaceTool, eave: Vector3, ridge: Vector3, dv: Vector3, el: float, er: float, rl: float, rr: float) -> void:
	if rl + rr < 0.0:
		var mid := (rr - rl) / 2.0
		rl = -mid
		rr = mid
	var side := Vector3.UP.cross(-dv)
	var n := (ridge - eave).cross(side).normalized()
	if n.y < 0:
		n = -n
	var w := maxf(el + er, 0.01)
	var pts := [[ridge - side * rl, Vector2((el - rl) / w, 0)], [ridge + side * rr, Vector2((el + rr) / w, 0)],
		[eave + side * er, Vector2(1, 1)], [ridge - side * rl, Vector2((el - rl) / w, 0)],
		[eave + side * er, Vector2(1, 1)], [eave - side * el, Vector2(0, 1)]]
	for v in pts:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


func _mat(tex: String, tint: Color, uv_scale := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Ui.tex(tex)
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.uv1_scale = Vector3(uv_scale, uv_scale, 1)
	return m


func _plain(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	return m


func _add(root: Node3D, st: SurfaceTool, m: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	root.add_child(mi)


func _box(root: Node3D, at: Vector3, sz: Vector3, m: Material, rot := Vector3.ZERO) -> void:
	var bm := BoxMesh.new()
	bm.size = sz
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = m
	mi.position = at
	mi.rotation = rot
	root.add_child(mi)


func _cyl(root: Node3D, at: Vector3, r: float, ht: float, m: Material, rot := Vector3.ZERO) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = ht
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = m
	mi.position = at
	mi.rotation = rot
	root.add_child(mi)


func _person(root: Node3D, at: Vector3, who: Dictionary) -> void:
	var sp := Sprite3D.new()
	sp.texture = FigureArt.texture_for(root, who.race, who.look)
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	var height: float = who.get("height", 1.75)
	sp.pixel_size = height / 256.0 * (128.0 / 122.0)
	sp.position = at + Vector3(0, height / 2.0 * (128.0 / 122.0) - 0.04, 0)
	root.add_child(sp)
