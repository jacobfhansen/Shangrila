class_name DungeonView
extends SubViewport
## First-person view of the mines. The original composed each view from seven pre-drawn
## strips (OVDB / DrawOutView); here the same map is built as real 3D geometry.

signal moved

const CELL := 2.0
const EYE := 0.95
const STEP_TIME := 0.16

var cam: Camera3D
var busy := false
var yaw := 0.0


func _ready() -> void:
	size = Vector2i(520, 520)
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	msaa_3d = Viewport.MSAA_2X
	var root := Node3D.new()
	add_child(root)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.27, 0.22)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.015, 0.01)
	env.fog_density = 0.12
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var wall_m := _mat("try2", Color(1.0, 0.95, 0.9))
	var floor_m := _mat("floor_tiles", Color(0.9, 0.85, 0.8))
	var ceil_m := _mat("rock", Color(0.6, 0.55, 0.5))
	var walls := _st()
	var floors := _st()
	var ceils := _st()
	var h := CELL / 2.0
	for cell: Vector2i in Game.mines:
		var c := Vector3(cell.x * CELL, 0, cell.y * CELL)
		_quad(floors, c, Vector3.UP, Vector3.FORWARD, h)
		_quad(ceils, c + Vector3(0, CELL, 0), Vector3.DOWN, Vector3.BACK, h)
		for d in 4:
			if Game.exit_open(cell, d):
				continue
			var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
			_quad(walls, c + dv * h + Vector3(0, h, 0), -dv, Vector3.UP, h)
	_add_mesh(root, walls, wall_m)
	_add_mesh(root, floors, floor_m)
	_add_mesh(root, ceils, ceil_m)

	# Daylight behind the entrance (the L1-L3 "light" pictures of the original).
	var sky := StandardMaterial3D.new()
	sky.albedo_texture = Ui.tex("SKY")
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky.disable_fog = true
	var start := Vector3(Game.MINES_START.x * CELL, 0, Game.MINES_START.y * CELL)
	var sky_st := _st()
	_quad(sky_st, start + Vector3(0, h, h - 0.01), Vector3.FORWARD, Vector3.UP, h)
	_add_mesh(root, sky_st, sky)
	var day := OmniLight3D.new()
	day.light_color = Color(0.7, 0.8, 1.0)
	day.light_energy = 1.2
	day.omni_range = 4.0
	day.position = start + Vector3(0, 1.2, 0.8)
	root.add_child(day)

	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.05
	root.add_child(cam)
	var torch := OmniLight3D.new()
	torch.light_color = Color(1.0, 0.78, 0.5)
	torch.light_energy = 2.2
	torch.omni_range = 9.0
	torch.omni_attenuation = 1.4
	torch.position = Vector3(0.15, 0.1, 0.1)
	cam.add_child(torch)
	var flicker := create_tween().set_loops()
	flicker.tween_property(torch, "light_energy", 1.95, 0.23)
	flicker.tween_property(torch, "light_energy", 2.25, 0.31)
	flicker.tween_property(torch, "light_energy", 2.05, 0.19)
	snap()


func _mat(tex: String, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Ui.tex(tex)
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.roughness = 0.95
	return m


func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Adds a square of half-size h at c, facing n, with u as its "up" direction.
func _quad(st: SurfaceTool, c: Vector3, n: Vector3, u: Vector3, h: float) -> void:
	var r := u.cross(n)
	var tl := c - r * h + u * h
	var tr := c + r * h + u * h
	var br := c + r * h - u * h
	var bl := c - r * h - u * h
	for v in [[tl, Vector2(0, 0)], [tr, Vector2(1, 0)], [br, Vector2(1, 1)], [tl, Vector2(0, 0)], [br, Vector2(1, 1)], [bl, Vector2(0, 1)]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])


func _add_mesh(root: Node3D, st: SurfaceTool, m: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	root.add_child(mi)


func _cell_pos(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL, EYE, cell.y * CELL)


## Place the camera at Game.pos / Game.facing without animation.
func snap() -> void:
	yaw = -Game.facing * PI / 2.0
	cam.position = _cell_pos(Game.pos)
	cam.rotation = Vector3(0, yaw, 0)


func turn(d: int) -> void:
	if busy:
		return
	Game.facing = posmod(Game.facing + d, 4)
	yaw -= d * PI / 2.0
	busy = true
	var tw := create_tween()
	tw.tween_property(cam, "rotation:y", yaw, STEP_TIME).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func():
		busy = false
		moved.emit())


## Move one cell in absolute direction `dir`. Returns false when a wall is in the way.
func step(dir: int) -> bool:
	if busy:
		return true
	if not Game.can_move(Game.pos, dir):
		var bump := create_tween()
		var p := cam.position
		var v := Vector3(Game.DIR_VEC[dir].x, 0, Game.DIR_VEC[dir].y) * 0.12
		busy = true
		bump.tween_property(cam, "position", p + v, 0.06)
		bump.tween_property(cam, "position", p, 0.08)
		bump.finished.connect(func(): busy = false)
		return false
	Game.pos += Game.DIR_VEC[dir]
	Game.visited[Game.pos] = true
	busy = true
	var tw := create_tween()
	tw.tween_property(cam, "position", _cell_pos(Game.pos), STEP_TIME).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func():
		busy = false
		moved.emit())
	return true
