class_name DungeonView
extends SubViewport
## First-person view of an area (MinesArea, LehanStreets, LehanTunnels). The original composed each
## view of the mines from seven pre-drawn strips (OVDB / DrawOutView); here the map is built as real
## 3D geometry. The area builds the scene and keeps its own position, facing and walls.

signal moved

const CELL := 2.0
const STEP_TIME := 0.16

var cam: Camera3D
var busy := false
var yaw := 0.0
var area: Object = null   # set before adding to the tree


func _ready() -> void:
	size = Vector2i(520, 520)
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	msaa_3d = Viewport.MSAA_2X
	var root := Node3D.new()
	add_child(root)
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.05
	root.add_child(cam)
	area.build(root, cam)
	snap()


func _cell_pos(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL, area.eye, cell.y * CELL)


func get_pos() -> Vector2i:
	return area.pos


func get_facing() -> int:
	return area.facing


func _can_move(from: Vector2i, dir: int) -> bool:
	return area.can_move(from, dir)


## Place the camera at the current position and facing without animation.
func snap() -> void:
	yaw = -get_facing() * PI / 2.0
	cam.position = _cell_pos(get_pos())
	cam.rotation = Vector3(0, yaw, 0)


func turn(d: int) -> void:
	if busy:
		return
	area.facing = posmod(area.facing + d, 4)
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
	if not _can_move(get_pos(), dir):
		var bump := create_tween()
		var p := cam.position
		var v := Vector3(Game.DIR_VEC[dir].x, 0, Game.DIR_VEC[dir].y) * 0.12
		busy = true
		bump.tween_property(cam, "position", p + v, 0.06)
		bump.tween_property(cam, "position", p, 0.08)
		bump.finished.connect(func(): busy = false)
		return false
	area.pos += Game.DIR_VEC[dir]
	busy = true
	var tw := create_tween()
	tw.tween_property(cam, "position", _cell_pos(get_pos()), STEP_TIME).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func():
		busy = false
		moved.emit())
	return true
