class_name MarshVillage
extends RefCounted
## Oggal, the Thuug stilt village on the causeway (shown by DungeonView, walked like Lehan's
## streets): boardwalks over black water, reed huts on stilts with thatched roofs, under a misty
## sky. The hub for the Drowned Shrine (see "The Drowned Shrine" in IDEAS.md).
##
## The map, north at the top:
##   .  boardwalk         ~  open water (seen over, not walked on)
##   #  a reed hut        G  the causeway gate (back to the world map)
##   T  Hett the trader's stall     H  the guest hut (rest, and the village's checkpoint)
##   U  Ubba's hut        E  the elder's longhouse
##   P  the causeway on to the old shrine
##   r  reeds   b  a boat   R  a fish rack
##   1-9  people (MarshData.PEOPLE)
## Huts, water and props block the way; walking into a door or a person uses it.

const MAP := [
	"~~~~~~~~~~~~~~~~",
	"~r~~###~~~~~~r~~",
	"~~~~#U#~~~###~~~",
	"~~###.2~~~#H#~~~",
	"~~#T#.~~~~~.~~r~",
	"~1~.~.~3~~~.~~~~",
	"G..............P",
	"~~~.~~~~R~~.~4~~",
	"~~5.~~~~~~~.~~~~",
	"~~~b~~~~~~#E#~~~",
	"~r~~~~~~~~###~r~",
	"~~~~~~~~~~~~~~~~",
]
const CELL := DungeonView.CELL
const WATER_Y := -0.35        # the water lies a little below the boardwalks
const WALL_H := 2.3           # reed walls, from the water up to the eaves
const HUT := "#TUHEG"
const WATER := "~rb"
const EXITS := {"G": "gate", "T": "trader", "H": "guest", "U": "ubba_hut", "E": "elder", "P": "shrine"}
const ENTRANCES := {
	"gate": {"cell": Vector2i(1, 6), "dir": 3},
	"trader": {"cell": Vector2i(3, 5), "dir": 0},
	"guest": {"cell": Vector2i(11, 4), "dir": 0},
	"shrine": {"cell": Vector2i(14, 6), "dir": 1},
}

var pos: Vector2i = ENTRANCES.gate.cell
var facing := 1
var eye := 1.35


func _char(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= MAP.size() or cell.x < 0 or cell.x >= MAP[cell.y].length():
		return "~"
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
## / {"kind": "water"} / {"kind": "wall"} / {} for open boardwalk.
func thing_at(cell: Vector2i) -> Dictionary:
	var ch := _char(cell)
	if ch == ".":
		return {}
	if EXITS.has(ch):
		return {"kind": "exit", "to": EXITS[ch]}
	if MarshData.PEOPLE.has(ch):
		return {"kind": "person", "id": ch}
	if ch == "~":
		return {"kind": "water"}
	if ch == "#":
		return {"kind": "wall"}
	return {"kind": "prop", "what": {"r": "reeds", "b": "boat", "R": "rack"}.get(ch, "")}


func ahead() -> Vector2i:
	return pos + Game.DIR_VEC[facing]


func _walkway(ch: String) -> bool:
	return ch == "." or ch == "R" or ch == "P" or MarshData.PEOPLE.has(ch)


# ---------------------------------------------------------------- building the scene

func build(root: Node3D, cam: Camera3D) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#7a8a90")
	sm.sky_horizon_color = Color("#c4ccc4")
	sm.ground_horizon_color = Color("#a8b0a4")
	sm.ground_bottom_color = Color("#4a5040")
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.78, 0.74)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true   # marsh mist
	env.fog_light_color = Color(0.72, 0.76, 0.72)
	env.fog_density = 0.022
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.light_energy = 0.6
	sun.rotation = Vector3(deg_to_rad(-40), deg_to_rad(-30), 0)
	root.add_child(sun)
	cam.fov = 75

	# The water: one wide sheet under everything, reaching out into the mist.
	var water := _st()
	var mid := Vector3((MAP[0].length() - 1) * CELL / 2.0, WATER_Y, (MAP.size() - 1) * CELL / 2.0)
	_quad(water, mid, Vector3.UP, Vector3.FORWARD, 60.0, 60.0)
	var wm := _mat("marsh_water", Color(0.6, 0.66, 0.6), 24.0)
	wm.roughness = 0.12
	wm.metallic = 0.1
	wm.metallic_specular = 0.8
	_add(root, water, wm)

	var walk := _st()
	var skirt := _st()
	var by_tex := {}
	var roofs := _st()
	var h := CELL / 2.0
	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			var ch := _char(cell)
			var c := Vector3(x * CELL, 0, y * CELL)
			if _walkway(ch):
				_quad(walk, c, Vector3.UP, Vector3.FORWARD, h, h)
				for d in 4:
					var n: Vector2i = cell + Game.DIR_VEC[d]
					if WATER.contains(_char(n)):
						var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
						_quad(skirt, c + dv * h + Vector3(0, WATER_Y / 2.0, 0), dv, Vector3.UP, h, -WATER_Y / 2.0)
						_post(root, c + dv * (h - 0.08) + Vector3(0, 0, 0))
				continue
			if not HUT.contains(ch):
				continue
			for d in 4:
				var n: Vector2i = cell + Game.DIR_VEC[d]
				var nch := _char(n)
				if HUT.contains(nch):
					continue
				var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
				var wall_c := c + dv * h
				var tex := "reed_wall"
				if _walkway(nch) or nch == "~":
					match ch:
						"T": tex = "trader_front" if _walkway(nch) else "reed_wall"
						"H": tex = "guest_front" if _walkway(nch) else "reed_wall"
						"U", "E": tex = "reed_door" if _walkway(nch) else "reed_wall"
						"G": tex = "causeway_gate"
				_tool(by_tex, tex)
				var bottom := WATER_Y
				_quad(by_tex[tex], wall_c + Vector3(0, (bottom + WALL_H) / 2.0, 0), dv, Vector3.UP, h, (WALL_H - bottom) / 2.0)
				if ch == "G":
					continue   # the gate is a palisade, no roof
				# A thatched roof sloping back from the eaves, hipped at the corners.
				var side_v := Vector3.UP.cross(dv)
				var side_g := Vector2i(roundi(side_v.x), roundi(side_v.z))
				var kl := _corner(cell, n, -side_g)
				var kr := _corner(cell, n, side_g)
				var eave_out := 0.45
				var depth := 1.5
				var eave := wall_c + dv * eave_out + Vector3(0, WALL_H - 0.1, 0)
				var ridge := wall_c - dv * depth + Vector3(0, WALL_H + 1.6, 0)
				_slope(roofs, eave, ridge, -dv, h + kl * eave_out, h + kr * eave_out, h - kl * depth, h - kr * depth)
	_add(root, walk, _mat("boardwalk", Color.WHITE, 1.0))
	_add(root, skirt, _mat("boardwalk", Color(0.7, 0.7, 0.65)))
	for t in by_tex:
		_add(root, by_tex[t], _mat(t, Color.WHITE))
	_add(root, roofs, _mat("thatch", Color(0.95, 0.92, 0.85)))

	for y in MAP.size():
		for x in MAP[y].length():
			var at := Vector3(x * CELL, 0, y * CELL)
			match MAP[y][x]:
				"r": _reeds(root, at, x * 7 + y * 3)
				"b": _boat(root, at)
				"R": _rack(root, at)
				"P": _shrine_way(root, at)
				var ch:
					if MarshData.PEOPLE.has(ch):
						_person(root, at, MarshData.PEOPLE[ch])
	# Reed beds out in the water, all around, fading into the mist.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(14.0, 30.0)
		_reeds(root, mid + Vector3(cos(a) * r, -WATER_Y, sin(a) * r * 0.8), i)


## 1 if hut `cell`'s wall facing open `n` ends at an outside corner on side `e`, -1 at an inside
## corner, 0 if it runs on.
func _corner(cell: Vector2i, n: Vector2i, e: Vector2i) -> int:
	if not HUT.contains(_char(cell + e)):
		return 1
	if HUT.contains(_char(n + e)):
		return -1
	return 0


func _post(root: Node3D, at: Vector3) -> void:
	_cyl(root, at + Vector3(0, WATER_Y / 2.0 - 0.1, 0), 0.07, -WATER_Y + 0.25, _plain(Color("#4a3a28")))


func _reeds(root: Node3D, at: Vector3, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 31 + 7
	var m := _plain(Color(0.42, 0.46, 0.26))
	var top := _plain(Color(0.36, 0.26, 0.16))
	for i in 9:
		var p := at + Vector3(rng.randf_range(-0.8, 0.8), WATER_Y, rng.randf_range(-0.8, 0.8))
		var ht := rng.randf_range(1.2, 2.2)
		var tilt := Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
		_cyl(root, p + Vector3(0, ht / 2.0, 0), 0.02, ht, m, tilt)
		if i % 3 == 0:
			_cyl(root, p + Vector3(tilt.z * ht * 0.5, ht - 0.1, -tilt.x * ht * 0.5), 0.05, 0.3, top, tilt)


func _boat(root: Node3D, at: Vector3) -> void:
	var wood := _mat("planks", Color(0.7, 0.62, 0.5))
	_box(root, at + Vector3(0, WATER_Y + 0.12, 0), Vector3(0.7, 0.25, 1.9), wood)
	_box(root, at + Vector3(0, WATER_Y + 0.2, 0), Vector3(0.5, 0.12, 1.6), _plain(Color("#2a2418")))
	_box(root, at + Vector3(0.25, WATER_Y + 0.35, 0.2), Vector3(0.05, 0.05, 1.8), wood, Vector3(0.2, 0, 0))


func _rack(root: Node3D, at: Vector3) -> void:
	var wood := _plain(Color("#5a4630"))
	for s in [-0.7, 0.7]:
		_box(root, at + Vector3(s, 0.85, 0), Vector3(0.08, 1.7, 0.08), wood)
	_box(root, at + Vector3(0, 1.6, 0), Vector3(1.6, 0.06, 0.06), wood)
	var fish := _plain(Color("#b0a080"))
	for i in 6:
		_box(root, at + Vector3(-0.55 + i * 0.22, 1.3, 0), Vector3(0.1, 0.5, 0.04), fish)


## Where the causeway goes on to the old shrine: two tall posts with a crossbar and hanging charms.
func _shrine_way(root: Node3D, at: Vector3) -> void:
	var wood := _plain(Color("#3a3024"))
	for s in [-0.85, 0.85]:
		_box(root, at + Vector3(0, 1.3, s), Vector3(0.14, 2.6, 0.14), wood)
	_box(root, at + Vector3(0, 2.55, 0), Vector3(0.12, 0.12, 2.0), wood)
	var bone := _plain(Color("#d8d0b8"))
	for i in 4:
		_box(root, at + Vector3(0, 2.2 - (i % 2) * 0.15, -0.5 + i * 0.33), Vector3(0.04, 0.3, 0.06), bone)


# ---------------------------------------------------------------- mesh helpers (as LehanStreets)

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
		var m := (rr - rl) / 2.0
		rl = -m
		rr = m
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
	var height: float = who.get("height", 1.7)
	sp.pixel_size = height / 256.0 * (128.0 / 122.0)
	sp.position = at + Vector3(0, height / 2.0 * (128.0 / 122.0) - 0.04, 0)
	root.add_child(sp)
