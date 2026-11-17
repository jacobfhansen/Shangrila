class_name LehanStreets
extends RefCounted
## The streets of Lehan as a walkable first-person area (shown by DungeonView): the market square
## in the middle, the road to the south gate, Tanners' Row, the lane to the inn and the street
## up to the weapon smith. See "A walkable market square" in IDEAS.md.
##
## The map is a grid of characters, north at the top:
##   .  cobbles you can walk on        #  a house front
##   G  the south gate     I  the inn's door     D  the weapon smith's door
##   H  the employer's house (Tanners' Row)
##   K  the council house's door    k  the rest of its front (north side of the square)
##   W  the well    S  a stall    C  a cart    B  barrels
##   1-9  people (MarketData.PEOPLE)
## Houses and doors block the way; walking into a door or a person uses it.

const MAP := [
	"#######################",
	"####D##################",
	"####.###kkkkKkkk#######",
	"####.###S..S..SB#######",
	"####.###.6......#######",
	"####..........2.#######",
	"########...1W........I#",
	"########........#######",
	"########.3....4.#######",
	"########S......C#######",
	"########.5......#######",
	"###########.###########",
	"###########.###########",
	"###########.###########",
	"###########.###########",
	"####H.......###########",
	"###########.###########",
	"###########.7##########",
	"###########.###########",
	"###########G###########",
]
const CELL := DungeonView.CELL
const STOREY := 2.0           # height of one storey of a house front
const BUILDING := "#DIGHKk"
const EXITS := {"D": "smith", "I": "inn", "G": "gate", "H": "hideout", "K": "council"}
## Where each place on the town map is entered: the street cell in front of it, and the
## direction of the door from there. The market is the square's south side.
const ENTRANCES := {
	"gate": {"cell": Vector2i(11, 18), "dir": 2},
	"market": {"cell": Vector2i(11, 10), "dir": 0},
	"inn": {"cell": Vector2i(20, 6), "dir": 1},
	"smith": {"cell": Vector2i(4, 2), "dir": 0},
	"hideout": {"cell": Vector2i(5, 15), "dir": 3},
	"council": {"cell": Vector2i(12, 3), "dir": 0},
}
## The company's walk on arriving (see LehanData): waypoints, turned and walked to in order.
const PATH_TO_HOUSE := [Vector2i(11, 15), Vector2i(5, 15)]
const PATH_TO_INN := [Vector2i(11, 15), Vector2i(11, 10), Vector2i(13, 10), Vector2i(13, 6), Vector2i(20, 6)]

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
	return not BUILDING.contains(_char(cell))


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
	if MarketData.PEOPLE.has(ch):
		return {"kind": "person", "id": ch}
	if ch == "#":
		return {"kind": "wall"}
	return {"kind": "prop", "what": {"W": "well", "S": "stall", "C": "cart", "B": "barrels"}.get(ch, "")}


func ahead() -> Vector2i:
	return pos + Game.DIR_VEC[facing]


# ---------------------------------------------------------------- building the scene

func build(root: Node3D, cam: Camera3D) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#5d86c0")
	sm.sky_horizon_color = Color("#c8d4e0")
	sm.ground_horizon_color = Color("#a89880")
	sm.ground_bottom_color = Color("#605040")
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.76, 0.72)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 0.9
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	root.add_child(sun)
	cam.fov = 75

	var floors := _st()
	var by_tex := {}   # texture name -> SurfaceTool
	var roofs := _st()
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
				var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
				var wall_c := c + dv * h
				var variant := absi(n.x * 7 + n.y * 13) % 4
				var low := "house_low_%d" % variant
				match ch:
					"D": low = "smith_front"
					"I": low = "inn_front"
					"G": low = "town_gate"
					"H": low = "house_low_0"
					"K": low = "council_door"
					"k": low = "council_low"
				# How the wall ends on either side (along `side`): 1 at an outside corner (the
				# building ends), -1 at an inside corner (another wall meets it), 0 if it runs on.
				# Overhangs grow or shrink by their depth at the corners so neighbours meet.
				var side_v := Vector3.UP.cross(-dv)
				var side_g := Vector2i(roundi(side_v.x), roundi(side_v.z))
				var kl := _corner(n, cell, -side_g)
				var kr := _corner(n, cell, side_g)
				_tool(by_tex, low)
				_quad(by_tex[low], wall_c + Vector3(0, STOREY / 2.0, 0), -dv, Vector3.UP, h, STOREY / 2.0)
				var up := "house_up_%d" % ((variant + 1) % 4)
				if ch == "K" or ch == "k":
					up = "council_up"
				_tool(by_tex, up)
				_tool(by_tex, "planks")
				var jut := 0.12   # the upper storey juts out a little over the street, as in old towns
				_quad_ext(by_tex[up], wall_c - dv * jut + Vector3(0, STOREY * 1.5, 0), -dv, Vector3.UP,
					h + kl * jut, h + kr * jut, STOREY / 2.0)
				# The underside of the overhang, closing the gap between the two storeys.
				_quad_ext(by_tex["planks"], wall_c - dv * jut / 2.0 + Vector3(0, STOREY, 0), Vector3.DOWN, -dv,
					h + kl * jut, h + kr * jut, jut / 2.0)
				# A roof sloping back from the eaves (a hip at outside corners, a valley at inside
				# ones), with a board along the edge and a soffit under the overhang.
				var eave_out := 0.3
				var depth := 1.6
				var eave := wall_c - dv * eave_out + Vector3(0, STOREY * 2.0, 0)
				var ridge := wall_c + dv * depth + Vector3(0, STOREY * 2.0 + 1.5, 0)
				_slope(roofs, eave, ridge, dv, h + kl * eave_out, h + kr * eave_out, h - kl * depth, h - kr * depth)
				_quad_ext(by_tex["planks"], eave + Vector3(0, -0.06, 0), -dv, Vector3.UP,
					h + kl * eave_out, h + kr * eave_out, 0.08)
				_quad_ext(by_tex["planks"], wall_c - dv * 0.21 + Vector3(0, STOREY * 2.0 - 0.13, 0), Vector3.DOWN, -dv,
					h + kl * 0.21, h + kr * 0.21, 0.1)
	_add(root, floors, _mat("cobbles", Color(0.95, 0.92, 0.88), 2.0))
	for t in by_tex:
		_add(root, by_tex[t], _mat(t, Color.WHITE))
	_add(root, roofs, _mat("roof_tiles", Color(0.9, 0.85, 0.8)))

	for y in MAP.size():
		for x in MAP[y].length():
			var at := Vector3(x * CELL, 0, y * CELL)
			match MAP[y][x]:
				"W": _well(root, at)
				"S": _stall(root, at, x + y)
				"C": _cart(root, at)
				"B": _barrels(root, at)
				var ch:
					if MarketData.PEOPLE.has(ch):
						_person(root, at, MarketData.PEOPLE[ch])


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _tool(d: Dictionary, key: String) -> void:
	if not d.has(key):
		d[key] = _st()


## A rectangle at c facing n, `u` up, half-width hw and half-height hh.
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


## A roof plane from the eave line up to the ridge line, both `hw` either side.
## 1 if building `n`'s wall (seen from open `cell`) ends at an outside corner on side `e`,
## -1 at an inside corner, 0 if it runs straight on.
func _corner(n: Vector2i, cell: Vector2i, e: Vector2i) -> int:
	if not BUILDING.contains(_char(n + e)):
		return 1
	if BUILDING.contains(_char(cell + e)):
		return -1
	return 0


## A rectangle like _quad, but reaching `left` and `right` out from the centre (along u x n).
func _quad_ext(st: SurfaceTool, c: Vector3, n: Vector3, u: Vector3, left: float, right: float, hh: float) -> void:
	var r := u.cross(n)
	var tl := c - r * left + u * hh
	var tr := c + r * right + u * hh
	var br := c + r * right - u * hh
	var bl := c - r * left - u * hh
	for v in [[tl, Vector2(0, 0)], [tr, Vector2(1, 0)], [br, Vector2(1, 1)], [tl, Vector2(0, 0)], [br, Vector2(1, 1)], [bl, Vector2(0, 1)]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


## A roof plane from the eave line up to the ridge line. Each edge reaches its own distance to
## either side, so the plane can end in a hip (narrower at the ridge) or run into a valley
## (wider at the ridge).
func _slope(st: SurfaceTool, eave: Vector3, ridge: Vector3, dv: Vector3, el: float, er: float, rl: float, rr: float) -> void:
	if rl + rr < 0.0:   # both ends hipped on a narrow building: meet in a point
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


func _box(root: Node3D, at: Vector3, sz: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = sz
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = m
	mi.position = at
	mi.rotation = rot
	root.add_child(mi)
	return mi


func _cyl(root: Node3D, at: Vector3, r: float, ht: float, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
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
	return mi


func _well(root: Node3D, at: Vector3) -> void:
	_cyl(root, at + Vector3(0, 0.38, 0), 0.6, 0.76, _mat("dark_stone", Color(1.1, 1.05, 1.0)))
	_cyl(root, at + Vector3(0, 0.77, 0), 0.48, 0.02, _plain(Color(0.03, 0.03, 0.05)))
	var wood := _mat("planks", Color.WHITE)
	for s in [-1.0, 1.0]:
		_box(root, at + Vector3(s * 0.62, 1.1, 0), Vector3(0.1, 1.5, 0.1), wood)
	_box(root, at + Vector3(0, 1.75, 0), Vector3(1.4, 0.1, 0.1), wood)
	var roof := PrismMesh.new()
	roof.size = Vector3(1.7, 0.5, 1.2)
	var mi := MeshInstance3D.new()
	mi.mesh = roof
	mi.material_override = _mat("roof_tiles", Color(0.85, 0.8, 0.75))
	mi.position = at + Vector3(0, 2.05, 0)
	root.add_child(mi)
	_cyl(root, at + Vector3(0, 1.3, 0), 0.12, 0.25, wood)


func _stall(root: Node3D, at: Vector3, seed_: int) -> void:
	var wood := _mat("planks", Color.WHITE)
	_box(root, at + Vector3(0, 0.45, 0), Vector3(1.6, 0.9, 0.9), wood)
	for sx in [-0.75, 0.75]:
		for sz in [-0.4, 0.4]:
			_box(root, at + Vector3(sx, 1.0, sz), Vector3(0.07, 2.0, 0.07), wood)
	_box(root, at + Vector3(0, 2.0, 0.1), Vector3(1.8, 0.04, 1.3), _mat("awning", Color.WHITE), Vector3(deg_to_rad(12), 0, 0))
	# Wares on the counter: fruit, cloth, pots.
	var cols := [Color("#c0402a"), Color("#e0b030"), Color("#6a9a40"), Color("#8a5aa0"), Color("#d08040")]
	for i in 5:
		var col: Color = cols[(i + seed_) % cols.size()]
		var p := at + Vector3(-0.6 + i * 0.3, 0.98, -0.1 + (i % 2) * 0.2)
		if (i + seed_) % 3 == 0:
			_box(root, p, Vector3(0.22, 0.14, 0.2), _plain(col))
		else:
			var sm := SphereMesh.new()
			sm.radius = 0.09
			sm.height = 0.18
			var mi := MeshInstance3D.new()
			mi.mesh = sm
			mi.material_override = _plain(col)
			mi.position = p
			root.add_child(mi)


func _cart(root: Node3D, at: Vector3) -> void:
	var wood := _mat("planks", Color(0.9, 0.85, 0.8))
	_box(root, at + Vector3(0, 0.7, 0), Vector3(1.0, 0.12, 1.5), wood)
	for s in [-1.0, 1.0]:
		_box(root, at + Vector3(s * 0.5, 0.9, 0), Vector3(0.06, 0.4, 1.5), wood)
		_cyl(root, at + Vector3(s * 0.6, 0.45, 0.2), 0.45, 0.08, _plain(Color("#4a3420")), Vector3(0, 0, PI / 2))
		_box(root, at + Vector3(s * 0.35, 0.55, -1.1), Vector3(0.06, 0.06, 1.0), wood, Vector3(deg_to_rad(-15), 0, 0))
	_box(root, at + Vector3(0, 1.0, 0.2), Vector3(0.7, 0.4, 0.8), _plain(Color("#a08a60")))


func _barrels(root: Node3D, at: Vector3) -> void:
	var m := _mat("planks", Color(0.8, 0.65, 0.5))
	for p in [Vector3(-0.35, 0, -0.25), Vector3(0.35, 0, -0.1), Vector3(-0.05, 0, 0.4)]:
		_cyl(root, at + p + Vector3(0, 0.45, 0), 0.32, 0.9, m)
		_cyl(root, at + p + Vector3(0, 0.9, 0), 0.3, 0.02, _plain(Color("#3a2a1a")))


func _person(root: Node3D, at: Vector3, who: Dictionary) -> void:
	var sp := Sprite3D.new()
	sp.texture = FigureArt.texture_for(root, who.race, who.look)
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	var height: float = who.get("height", 1.7)
	sp.pixel_size = height / 256.0 * (128.0 / 122.0)
	sp.position = at + Vector3(0, height / 2.0 * (128.0 / 122.0) - 0.04, 0)
	root.add_child(sp)
