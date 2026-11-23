class_name ShrineArea
extends RefCounted
## The Drowned Shrine: its overgrown grounds, open to the sky (level 1), and later the temple
## under them (step 4). Walked by the dungeon screen like the mines (Game.site == "shrine"), with
## the same static API as MinesArea; what happens here is in ShrineQuest. See "The Drowned Shrine"
## in IDEAS.md.
##
## The grounds, north at the top:
##   #  ruined wall, vine-covered     .  wet flagstones     ,  shallow water (walked through)
##   ~  a deep pool                   r  reeds              s  a fallen statue
##   E  the causeway back to Oggal    D  the sunken door (in the inner court's wall)
##   W  the carving that tells the story (and the sigils' order)
##   1 2 3  the three sigils (stepped on)     F  Old Moss's fish pens (stepped on)
##   N  the Reed Stalkers' nest (a placed group)   T  the Mire Toad (a placed group)
##   c  an old offering box

const START := Vector2i(6, 14)
const START_FACING := 0
const NAMES := ["The shrine grounds", "The drowned temple"]
const WALL_LOW := 1.9
const WALL_HIGH := 3.1
const POOL_Y := -0.45

const MAPS := [
	[
		"##################",
		"#rr..~~~~~#c#r..r#",
		"#r..,,~~~~#T#....#",
		"#...,2,~~~#.###..#",
		"#..,,,,,..#.#W#..#",
		"#s.........1.....#",
		"###.###..##D##.###",
		"#.....#..#...#...#",
		"#.~~..#..#...#.N.#",
		"#.~~.....#...##3##",
		"#.....#..##.##.#r#",
		"#..F..#.........r#",
		"#rr...#####.####.#",
		"#,,,....r.......,#",
		"#~~,,..........,,#",
		"######E###########",
	],
]
const THINGS := [
	{"E": {"kind": "exit"}, "D": {"kind": "shrine_door"}, "W": {"kind": "carving"}, "1": {"kind": "sigil"},
		"2": {"kind": "sigil"}, "3": {"kind": "sigil"}, "F": {"kind": "pens"}, "N": {"kind": "group"},
		"T": {"kind": "group"}, "c": {"kind": "chest"}, "s": {"kind": "statue"}, "r": {"kind": "reeds"},
		"~": {"kind": "pool"}},
]
const SOLID := ["exit", "chest", "shrine_door", "statue", "reeds", "pool", "carving"]
const GATES := []
const IN_ROCK := ["carving", "shrine_door"]
const OPEN := ".,"   # floor you walk on (',' with shallow water over it)

var eye := 1.0
var level: int:
	get: return Game.mine_level
var pos: Vector2i:
	get: return Game.pos
	set(v):
		Game.pos = v
		Game.visited[Vector3i(v.x, v.y, Game.vz())] = true
var facing: int:
	get: return Game.facing
	set(v): Game.facing = v


static func char_at(lv: int, cell: Vector2i) -> String:
	if lv < 1 or lv > MAPS.size() or cell.y < 0 or cell.y >= MAPS[lv - 1].size() \
			or cell.x < 0 or cell.x >= MAPS[lv - 1][cell.y].length():
		return "#"
	return MAPS[lv - 1][cell.y][cell.x]


static func kind_of(lv: int, ch: String) -> String:
	return THINGS[lv - 1].get(ch, {}).get("kind", "")


static func key(lv: int, ch: String) -> String:
	return "%d%s" % [lv, ch]


static func cleared(lv: int, ch: String, _cell := Vector2i.ZERO) -> bool:
	var q := func(k: String) -> String: return LehanQuests.get_q(k)
	match kind_of(lv, ch):
		"group": return q.call("s_grp_" + key(lv, ch)) != ""
		"chest": return q.call("s_chest_" + key(lv, ch)) != ""
		"sigil": return q.call("s_sigil_" + ch) != ""
		"pens": return q.call("marsh_leeches") == "done"
		"shrine_door": return q.call("s_door") != ""
	return false


static func walkable(lv: int, cell: Vector2i) -> bool:
	var ch := char_at(lv, cell)
	if ch == "#":
		return false
	return not kind_of(lv, ch) in SOLID


static func arrive_near(lv: int, ch: String) -> Array:
	for y in MAPS[lv - 1].size():
		var x: int = MAPS[lv - 1][y].find(ch)
		if x < 0:
			continue
		var at := Vector2i(x, y)
		for d in [2, 1, 3, 0]:
			var n: Vector2i = at + Game.DIR_VEC[d]
			if walkable(lv, n):
				return [n, d]
	return []


func _char(cell: Vector2i) -> String:
	return char_at(level, cell)


func size() -> Vector2i:
	return Vector2i(MAPS[level - 1][0].length(), MAPS[level - 1].size())


func is_open(cell: Vector2i) -> bool:
	return walkable(level, cell)


func can_move(from: Vector2i, dir: int) -> bool:
	return walkable(level, from + Game.DIR_VEC[dir])


func thing_at(cell: Vector2i) -> Dictionary:
	var ch := _char(cell)
	if ch == "#":
		return {"kind": "wall"}
	if OPEN.contains(ch):
		return {}
	var k := kind_of(level, ch)
	if k == "":
		return {}
	var gone := cleared(level, ch, cell)
	if gone and k in ["group", "sigil", "pens"]:
		return {}
	return {"kind": k, "ch": ch, "key": key(level, ch), "cell": cell, "done": gone}


func ahead() -> Vector2i:
	return pos + Game.DIR_VEC[facing]


# ---------------------------------------------------------------- the 3D view

func _rocky(cell: Vector2i) -> bool:
	var ch := _char(cell)
	return ch == "#" or kind_of(level, ch) in IN_ROCK


## How tall the ruined wall stands on a square (broken down in places).
func _height(cell: Vector2i) -> float:
	var hsh := absi(cell.x * 73856093 ^ cell.y * 19349663) % 100
	if _char(cell) != "#":
		return 2.8
	return WALL_LOW + (WALL_HIGH - WALL_LOW) * hsh / 100.0


func build(root: Node3D, cam: Camera3D) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#6e7c84")
	sm.sky_horizon_color = Color("#b8c0b4")
	sm.ground_horizon_color = Color("#9aa094")
	sm.ground_bottom_color = Color("#3a4034")
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.74, 0.68)
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color(0.66, 0.7, 0.64)
	env.fog_density = 0.035
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 0.55
	sun.rotation = Vector3(deg_to_rad(-45), deg_to_rad(25), 0)
	root.add_child(sun)
	cam.fov = 75

	var cs := DungeonView.CELL
	var h := cs / 2.0
	var by_tex := {}
	var floors := _st()
	var shallow := _st()
	var pools := _st()
	var tops := _st()
	var sz := size()
	var door_open := cleared(level, "D")
	for y in sz.y:
		for x in sz.x:
			var cell := Vector2i(x, y)
			var ch := _char(cell)
			var c := Vector3(x * cs, 0, y * cs)
			if _rocky(cell):
				# The top of the ruined wall, and its sides where a lower neighbour leaves them bare.
				var ht := _height(cell)
				_quad(tops, c + Vector3(0, ht, 0), Vector3.UP, Vector3.FORWARD, h, h)
				for d in 4:
					var n: Vector2i = cell + Game.DIR_VEC[d]
					if not _rocky(n):
						continue
					var hn := _height(n)
					if hn < ht:
						var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
						_tool(by_tex, "vine_wall")
						_quad(by_tex["vine_wall"], c + dv * h + Vector3(0, (ht + hn) / 2.0, 0), dv, Vector3.UP, h, (ht - hn) / 2.0)
				continue
			if ch == "~":
				_quad(pools, c + Vector3(0, POOL_Y, 0), Vector3.UP, Vector3.FORWARD, h, h)
			else:
				_quad(floors, c, Vector3.UP, Vector3.FORWARD, h, h)
				if ch == ",":
					_quad(shallow, c + Vector3(0, 0.07, 0), Vector3.UP, Vector3.FORWARD, h, h)
			for d in 4:
				var n: Vector2i = cell + Game.DIR_VEC[d]
				var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
				if ch == "E" and (n.y >= sz.y or n.y < 0 or n.x < 0 or n.x >= sz.x):
					continue   # the gap in the outer wall: open to the marsh and the causeway
				if _rocky(n):
					var nch := _char(n)
					var tex := "vine_wall"
					match kind_of(level, nch):
						"carving": tex = "shrine_carving"
						"shrine_door": tex = "shrine_door_open" if door_open else "shrine_door"
					var ht := _height(n)
					var bottom := POOL_Y if ch == "~" else 0.0
					if tex != "vine_wall":
						# The door and the carving fill the lower part; plain wall above them.
						_tool(by_tex, tex)
						_quad(by_tex[tex], c + dv * h + Vector3(0, h, 0), -dv, Vector3.UP, h, h)
						_tool(by_tex, "vine_wall")
						if ht > cs:
							_quad(by_tex["vine_wall"], c + dv * h + Vector3(0, (cs + ht) / 2.0, 0), -dv, Vector3.UP, h, (ht - cs) / 2.0)
						continue
					_tool(by_tex, tex)
					_quad(by_tex[tex], c + dv * h + Vector3(0, (bottom + ht) / 2.0, 0), -dv, Vector3.UP, h, (ht - bottom) / 2.0)
				elif ch != "~" and _char(n) == "~":
					# The stone rim of a pool.
					_tool(by_tex, "vine_wall")
					_quad(by_tex["vine_wall"], c + dv * h + Vector3(0, POOL_Y / 2.0, 0), dv, Vector3.UP, h, -POOL_Y / 2.0)
	_add(root, floors, _mat("shrine_floor", Color.WHITE))
	var wm := _mat("marsh_water", Color(0.55, 0.62, 0.56), 1.0)
	wm.roughness = 0.1
	wm.metallic_specular = 0.8
	_add(root, pools, wm)
	var sw := _mat("marsh_water", Color(0.6, 0.7, 0.62, 0.55))
	sw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sw.roughness = 0.1
	_add(root, shallow, sw)
	_add(root, tops, _mat("vine_wall", Color(0.7, 0.8, 0.65)))
	for t in by_tex:
		_add(root, by_tex[t], _mat(t, Color.WHITE))

	for y in sz.y:
		for x in sz.x:
			var cell := Vector2i(x, y)
			var ch := _char(cell)
			var at := Vector3(x * cs, 0, y * cs)
			var done := cleared(level, ch, cell)
			match kind_of(level, ch):
				"reeds": _reeds(root, at, x * 7 + y * 3, 0.0)
				"statue": _statue(root, at, true)
				"chest": _chest(root, at, done)
				"exit": _causeway(root, cell)
				"sigil":
					if ch == "1":
						_statue(root, at, false)
					if not done:
						_glint(root, at + Vector3(0, 0.12 if ch != "1" else 0.55, 0))
				"pens":
					_pens(root, at)
				"group":
					if ch == "N":
						_reeds(root, at + Vector3(0, 0, 0.5), 91, 0.0)
					elif not done:
						_mound(root, at)
	# Reeds and the marsh beyond the walls, fading into the mist.
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var mid := Vector3((sz.x - 1) * cs / 2.0, 0, (sz.y - 1) * cs / 2.0)
	var outer := _st()
	_quad(outer, mid + Vector3(0, POOL_Y - 0.05, 0), Vector3.UP, Vector3.FORWARD, 70.0, 70.0)
	_add(root, outer, _mat("marsh_water", Color(0.5, 0.56, 0.5), 30.0))
	for i in 60:
		var a := rng.randf() * TAU
		var r := rng.randf_range(22.0, 40.0)
		_reeds(root, mid + Vector3(cos(a) * r, 0, sin(a) * r * 0.85), i + 300, POOL_Y)


# ---------------------------------------------------------------- props

func _reeds(root: Node3D, at: Vector3, seed_: int, base_y: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 31 + 7
	var m := _plain(Color(0.42, 0.46, 0.26))
	var top := _plain(Color(0.36, 0.26, 0.16))
	for i in 10:
		var p := at + Vector3(rng.randf_range(-0.8, 0.8), base_y, rng.randf_range(-0.8, 0.8))
		var ht := rng.randf_range(1.2, 2.3)
		var tilt := Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
		_cyl(root, p + Vector3(0, ht / 2.0, 0), 0.02, ht, m, tilt)
		if i % 3 == 0:
			_cyl(root, p + Vector3(tilt.z * ht * 0.5, ht - 0.1, -tilt.x * ht * 0.5), 0.05, 0.3, top, tilt)


## A fallen statue: a toppled body and a head lying apart, worn smooth. `whole`: on its own square;
## otherwise a smaller broken one at the side, with something on it.
func _statue(root: Node3D, at: Vector3, whole: bool) -> void:
	var stone := _mat("vine_wall", Color(0.8, 0.82, 0.76))
	if whole:
		_box(root, at + Vector3(0, 0.35, 0), Vector3(0.7, 0.7, 1.7), stone, Vector3(0, 0.4, 0.1))
		_box(root, at + Vector3(0.5, 0.25, 0.9), Vector3(0.5, 0.5, 0.5), stone, Vector3(0.3, 0.5, 0))
	else:
		_box(root, at + Vector3(0, 0.22, 0), Vector3(0.9, 0.44, 0.6), stone, Vector3(0, 0.3, 0))


## Something small catching the light (a sigil not yet taken).
func _glint(root: Node3D, at: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.8, 0.6)
	m.emission_enabled = true
	m.emission = Color(0.9, 0.85, 0.5)
	m.emission_energy_multiplier = 0.8
	_box(root, at, Vector3(0.18, 0.05, 0.18), m, Vector3(0, 0.6, 0))


## Old Moss's fish pens: a ring of wicker fencing standing in the water.
func _pens(root: Node3D, at: Vector3) -> void:
	var wood := _plain(Color("#6a5432"))
	for i in 10:
		var a := i * TAU / 10.0
		_box(root, at + Vector3(cos(a) * 0.8, 0.35, sin(a) * 0.8), Vector3(0.06, 0.7, 0.06), wood)
	for yy in [0.25, 0.5]:
		for i in 10:
			var a := (i + 0.5) * TAU / 10.0
			_box(root, at + Vector3(cos(a) * 0.8, yy, sin(a) * 0.8), Vector3(0.5, 0.05, 0.04), wood, Vector3(0, -a, 0))
	var wm := _mat("marsh_water", Color(0.4, 0.46, 0.4))
	_cyl(root, at + Vector3(0, 0.05, 0), 0.78, 0.04, wm)


func _mound(root: Node3D, at: Vector3) -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.8
	sm.height = 0.6
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.material_override = _plain(Color(0.28, 0.26, 0.18))
	mi.position = at + Vector3(0, 0.05, 0)
	root.add_child(mi)


## The way back: the causeway's boardwalk running off south into the mist.
## The causeway back to Oggal, out through the gap in the south wall and away over the marsh.
func _causeway(root: Node3D, cell: Vector2i) -> void:
	var cs := DungeonView.CELL
	var c := Vector3(cell.x * cs, 0, cell.y * cs)
	var st := _st()
	_quad(st, c + Vector3(0, 0.01, 0), Vector3.UP, Vector3.FORWARD, 0.75, cs / 2.0)
	_add(root, st, _mat("boardwalk", Color.WHITE))
	MarshVillage.causeway(root, c + Vector3(0, 0, cs / 2.0), Vector3(0, 0, 1), POOL_Y - 0.05, 37)


func _chest(root: Node3D, at: Vector3, open: bool) -> void:
	var stone := _mat("vine_wall", Color(0.75, 0.76, 0.7))
	_box(root, at + Vector3(0, 0.25, 0), Vector3(0.8, 0.5, 0.5), stone)
	if open:
		_box(root, at + Vector3(0.1, 0.05, 0.55), Vector3(0.8, 0.1, 0.5), stone, Vector3(0, 0.3, 0))
	else:
		_box(root, at + Vector3(0, 0.55, 0), Vector3(0.84, 0.1, 0.54), stone)


# ---------------------------------------------------------------- mesh helpers

func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _tool(d: Dictionary, k: String) -> void:
	if not d.has(k):
		d[k] = _st()


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
