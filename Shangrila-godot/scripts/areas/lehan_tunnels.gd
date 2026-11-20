class_name LehanTunnels
extends RefCounted
## The old tunnels under Lehan, below the tannery on Tanners' Row (Skee's quest, see SkeeQuest).
## Older than the streets above: stone-lined passages, a rat nest, a collapse, and at the far end
## the chamber of the blue lights. Walked in first person by the tunnels screen, lit by a torch.
##
## The map, north at the top:
##   .  passage     #  rock     U  the ladder up to the tannery (walk into it to climb out)
##   r  the rats (a scene the first time you step there, until they are dealt with)
##   c  the collapse (blocks the way until a way through is found)
##   o  a bag dropped by someone who ran (Skee's)
##   L  the chamber of the lights

const MAP := [
	"##############",
	"#U...#########",
	"####.#########",
	"##......r...##",
	"##.####.###.##",
	"##.####.###.##",
	"##....#.###c##",
	"#####.#...#.##",
	"#####...#o#.##",
	"#########.#.##",
	"###########L##",
	"##############",
]
const CELL := DungeonView.CELL
const START := Vector2i(2, 1)    # at the foot of the ladder, facing east
const LIGHTS := Vector2i(11, 10)

var pos: Vector2i = START
var facing := 1
var eye := 1.2


func _char(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= MAP.size() or cell.x < 0 or cell.x >= MAP[cell.y].length():
		return "#"
	return MAP[cell.y][cell.x]


func size() -> Vector2i:
	return Vector2i(MAP[0].length(), MAP.size())


func is_open(cell: Vector2i) -> bool:
	var ch := _char(cell)
	return ch in [".", "r", "L"] or (ch == "c" and SkeeQuest.collapse_passed()) or (ch == "o" and SkeeQuest.bag_taken())


func can_move(from: Vector2i, dir: int) -> bool:
	return is_open(from + Game.DIR_VEC[dir])


## What is in a cell: {"kind": "ladder"} / {"kind": "collapse"} / {"kind": "bag"} / {"kind":
## "rats"} / {"kind": "lights"} / {"kind": "wall"} / {} for open passage.
func thing_at(cell: Vector2i) -> Dictionary:
	match _char(cell):
		"U": return {"kind": "ladder"}
		"c": return {} if SkeeQuest.collapse_passed() else {"kind": "collapse"}
		"o": return {} if SkeeQuest.bag_taken() else {"kind": "bag"}
		"r": return {} if SkeeQuest.rats_done() else {"kind": "rats"}
		"L": return {"kind": "lights"}
		"#": return {"kind": "wall"}
	return {}


func ahead() -> Vector2i:
	return pos + Game.DIR_VEC[facing]


# ---------------------------------------------------------------- building the scene

func build(root: Node3D, cam: Camera3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.22, 0.2)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.015, 0.012, 0.01)
	env.fog_density = 0.14
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	cam.fov = 72

	var walls := _st()
	var carved := _st()
	var floors := _st()
	var ceils := _st()
	var h := CELL / 2.0
	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			var ch := _char(cell)
			if ch == "#" or ch == "U":
				continue
			var c := Vector3(x * CELL, 0, y * CELL)
			_quad(floors, c, Vector3.UP, Vector3.FORWARD, h, h)
			_quad(ceils, c + Vector3(0, CELL, 0), Vector3.DOWN, Vector3.BACK, h, h)
			for d in 4:
				var n: Vector2i = cell + Game.DIR_VEC[d]
				var nc := _char(n)
				if nc != "#" and nc != "U":
					continue
				var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
				var wall_c := c + dv * h + Vector3(0, h, 0)
				if nc == "U":
					_quad(walls, wall_c, -dv, Vector3.UP, h, h)
					_ladder(root, wall_c - dv * 0.08)
				elif ch == "L":
					_quad(carved, wall_c, -dv, Vector3.UP, h, h)
				else:
					_quad(walls, wall_c, -dv, Vector3.UP, h, h)
	_add(root, walls, _mat("try2", Color(0.85, 0.8, 0.75)))
	_add(root, carved, _mat("try2", Color(0.68, 0.7, 0.78)))   # older, colder stone in the chamber
	_add(root, floors, _mat("floor_tiles", Color(0.7, 0.65, 0.6)))
	_add(root, ceils, _mat("rock", Color(0.5, 0.46, 0.42)))

	for y in MAP.size():
		for x in MAP[y].length():
			var at := Vector3(x * CELL, 0, y * CELL)
			match MAP[y][x]:
				"c":
					if not SkeeQuest.collapse_passed():
						_rubble(root, at)
				"o":
					if not SkeeQuest.bag_taken():
						_box(root, at + Vector3(0, 0.15, 0), Vector3(0.5, 0.3, 0.35), _plain(Color("#5a4630")), Vector3(0, 0.4, 0))
				"r":
					if not SkeeQuest.rats_done():
						_rats(root, at)
				"L":
					_lights(root, at)

	# A little daylight comes down the ladder shaft from the tannery.
	var day := OmniLight3D.new()
	day.light_color = Color(0.8, 0.75, 0.6)
	day.light_energy = 0.8
	day.omni_range = 3.5
	day.position = Vector3(START.x * CELL - h + 0.3, CELL - 0.2, START.y * CELL)
	root.add_child(day)
	var torch := OmniLight3D.new()
	torch.light_color = Color(1.0, 0.78, 0.5)
	torch.light_energy = 2.0
	torch.omni_range = 8.0
	torch.omni_attenuation = 1.4
	torch.position = Vector3(0.15, 0.1, 0.1)
	cam.add_child(torch)
	var flicker := torch.create_tween().set_loops()
	flicker.tween_property(torch, "light_energy", 1.8, 0.23)
	flicker.tween_property(torch, "light_energy", 2.1, 0.31)
	flicker.tween_property(torch, "light_energy", 1.9, 0.19)


func _ladder(root: Node3D, at: Vector3) -> void:
	var wood := _plain(Color("#6a4a2a"))
	var side := Vector3(0, 0, 0.35)   # the ladder stands against the west wall: rails along z
	for s in [-1, 1]:
		_box(root, at + side * s, Vector3(0.08, CELL, 0.08), wood)
	for i in 6:
		_box(root, at + Vector3(0, -0.8 + i * 0.32, 0), Vector3(0.06, 0.05, 0.7), wood)


func _rubble(root: Node3D, at: Vector3) -> void:
	var stone := _plain(Color("#6a625a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var s := rng.randf_range(0.3, 0.8)
		_box(root, at + Vector3(rng.randf_range(-0.8, 0.8), s / 2 + rng.randf_range(0, 0.9), rng.randf_range(-0.8, 0.8)),
			Vector3(s, s * 0.8, s), stone, Vector3(rng.randf(), rng.randf(), rng.randf()))


func _rats(root: Node3D, at: Vector3) -> void:
	var fur := _plain(Color("#2a2420"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 9:
		var r := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 0.09
		m.height = 0.14
		r.mesh = m
		r.material_override = fur
		r.scale = Vector3(1.0, 1.0, 1.8)
		r.position = at + Vector3(rng.randf_range(-0.8, 0.8), 0.07, rng.randf_range(-0.8, 0.8))
		r.rotation.y = rng.randf() * TAU
		root.add_child(r)


func _lights(root: Node3D, at: Vector3) -> void:
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.45, 0.65, 1.0)
	glow.light_energy = 2.6
	glow.omni_range = 6.0
	glow.position = at + Vector3(0, 1.0, 0.6)
	root.add_child(glow)
	var pulse := glow.create_tween().set_loops()
	pulse.tween_property(glow, "light_energy", 1.6, 1.4)
	pulse.tween_property(glow, "light_energy", 2.8, 1.6)
	# The broken figure: a stump on its base and a heap of pieces, a few of them glowing.
	var dead := _mat("try2", Color(0.8, 0.78, 0.74))
	var lit := StandardMaterial3D.new()
	lit.albedo_texture = Ui.tex("try2")
	lit.emission_enabled = true
	lit.emission = Color(0.25, 0.4, 0.8)
	lit.emission_energy_multiplier = 0.9
	# What is left of the bricks that once walled the doorway (the open side, north).
	var brick := _plain(Color("#5a4a3e"))
	var h := CELL / 2.0
	for sx in [-1, 1]:
		_box(root, at + Vector3(sx * (h - 0.25), 0.25, -h + 0.12), Vector3(0.5, 0.5, 0.2), brick)
	var brng := RandomNumberGenerator.new()
	brng.seed = 31
	for i in 7:
		_box(root, at + Vector3(brng.randf_range(-h + 0.2, h - 0.2), 0.05, -h + brng.randf_range(0.2, 0.7)),
			Vector3(0.24, 0.1, 0.12), brick, Vector3(0, brng.randf() * TAU, 0))
	var base := at + Vector3(0, 0, 0.45)
	_box(root, base + Vector3(0, 0.1, 0), Vector3(0.8, 0.2, 0.6), dead)
	_box(root, base + Vector3(0.05, 0.38, 0), Vector3(0.36, 0.36, 0.3), dead, Vector3(0, 0.2, 0.08))
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in 12:
		var s := rng.randf_range(0.1, 0.32)
		_box(root, base + Vector3(rng.randf_range(-0.8, 0.8), s * 0.4, rng.randf_range(-0.7, 0.4)),
			Vector3(s, s * 0.7, s * 0.9), lit if i % 4 == 1 else dead, Vector3(rng.randf(), rng.randf() * TAU, rng.randf()))


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


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


func _mat(tex: String, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Ui.tex(tex)
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.roughness = 0.95
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
