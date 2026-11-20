class_name MinesArea
extends RefCounted
## The mines above Lehan: three levels, walked in first person by the dungeon screen (see "The
## mines: levels, grinding and story" in IDEAS.md). What happens in them, the scenes, chests and
## placed monsters, is in MinesQuest; this file holds the maps and builds the 3D view.
##
## The party's place is Game.mine_level, Game.pos and Game.facing (so it is saved with the game);
## `pos` and `facing` here pass through to them, and every square stepped on is marked visited.
##
## The maps, north at the top. Shared:
##   #  rock    .  passage    C  a camp (safe to rest)    L  the lift
##   >  the way down    <  the way up    n  something written (read on stepping there)
##   p  a trap (spotted or sprung on stepping there)
##   a lower-case letter or digit, or the letters below: see THINGS for each level.

const START := Vector2i(12, 16)   # level 1, inside the entrance
const START_FACING := 1            # east, along the first gallery
const NAMES := ["The old workings", "The new diggings", "The sealed galleries"]

const MAPS := [
	[
		"##################",
		"#b..k.#r.......#d#",
		"#####.#.######.#s#",
		"#.#...#.#....#.#.#",
		"#.#.###.#.##.#...#",
		"#...#...#..#.###.#",
		"###.#.###..#.#a#.#",
		"#...#.#.####.#C#.#",
		"#.#.#.#..n.#...#.#",
		"###...####.###.#.#",
		"#>c..p.....#...l##",
		"###.##.###.#.#####",
		"#...#....#...#..##",
		"#.#.#.##.#.#.#.#L#",
		"#.#...#..#.#...#.#",
		"#.#####.##.#####.#",
		"#................#",
		"############E#####",
	],
	[
		"##################",
		"#<...#.....###..g#",
		"####.#.###.#.#F###",
		"#.#..#.#Y#.#.#...#",
		"#.#.##.#.#.#.#.#.#",
		"#...o#...#...#.#.#",
		"###.###A##.###.#.#",
		"#C.....#.......#.#",
		"#.##.#.#.###.#.#.#",
		"#.#n.#...#.#.#...#",
		"#.####.###.#.###.#",
		"#.....D#...#.....#",
		"#.##.#.#.####.##.#",
		"#..#.#...#S..W...#",
		"##.#.#.#####w#.#L#",
		"#o.#...#v.......##",
		"#..###.####u#..X>#",
		"##################",
	],
	[
		"##################",
		"########G#########",
		"######..R..#######",
		"######.....#######",
		"########.#########",
		"#####P...####j.h##",
		"#1#2#3##.#####..##",
		"#.......K.....Z###",
		"#.####i#.####.####",
		"#.#....#.#....#..#",
		"#.#.##.#.#.##.#.##",
		"#...#..O.....p..L#",
		"###.#.####.#.##.##",
		"#C..#.Q..#.#....##",
		"#.###.##.#.####.##",
		"#..........#.....#",
		"#<....###......###",
		"##################",
	],
]

## What the letters on each level are. Kinds:
##   solid (used from the square in front, never walked into): exit, down, up, lift, chest, lever,
##     npc, warden; and set into the rock like walls: vein, tomb, pillar, words
##   gates (solid until dealt with, then open passage): cart, secret, air, door, water, ward
##   stepped on: camp, group (placed monsters), note, trap, breach
const THINGS := [
	{"E": {"kind": "exit"}, ">": {"kind": "down"}, "L": {"kind": "lift"}, "C": {"kind": "camp"},
		"a": {"kind": "chest"}, "b": {"kind": "chest"}, "d": {"kind": "chest"},
		"k": {"kind": "group"}, "r": {"kind": "group"}, "c": {"kind": "cart"}, "s": {"kind": "secret"},
		"l": {"kind": "lever"}, "n": {"kind": "note"}, "p": {"kind": "trap"}},
	{"<": {"kind": "up"}, ">": {"kind": "down"}, "L": {"kind": "lift"}, "C": {"kind": "camp"},
		"g": {"kind": "chest"}, "F": {"kind": "door"}, "A": {"kind": "air"}, "w": {"kind": "water"},
		"u": {"kind": "lever"}, "v": {"kind": "lever"}, "o": {"kind": "vein"}, "Y": {"kind": "group"},
		"D": {"kind": "group"}, "W": {"kind": "group"}, "S": {"kind": "npc"}, "X": {"kind": "breach"},
		"n": {"kind": "note"}},
	{"<": {"kind": "up"}, "L": {"kind": "lift"}, "C": {"kind": "camp"}, "1": {"kind": "pillar"},
		"2": {"kind": "pillar"}, "3": {"kind": "pillar"}, "i": {"kind": "words"}, "Z": {"kind": "ward"},
		"h": {"kind": "chest"}, "j": {"kind": "chest"}, "P": {"kind": "npc"}, "R": {"kind": "warden"},
		"G": {"kind": "tomb"}, "O": {"kind": "group"}, "Q": {"kind": "group"}, "K": {"kind": "group"},
		"p": {"kind": "trap"}},
]
const SOLID := ["exit", "down", "up", "lift", "chest", "lever", "npc", "warden", "vein", "tomb", "pillar", "words"]
const GATES := ["cart", "secret", "air", "door", "water", "ward"]
const IN_ROCK := ["vein", "tomb", "pillar", "words"]   # built as walls, with their own look

var eye := 1.0
var level: int:
	get: return Game.mine_level
var pos: Vector2i:
	get: return Game.pos
	set(v):
		Game.pos = v
		Game.visited[Vector3i(v.x, v.y, Game.mine_level)] = true
var facing: int:
	get: return Game.facing
	set(v): Game.facing = v


static func _row(lv: int, y: int) -> String:
	return MAPS[lv - 1][y]


static func char_at(lv: int, cell: Vector2i) -> String:
	if lv < 1 or lv > MAPS.size() or cell.y < 0 or cell.y >= MAPS[lv - 1].size() \
			or cell.x < 0 or cell.x >= MAPS[lv - 1][cell.y].length():
		return "#"
	return MAPS[lv - 1][cell.y][cell.x]


static func kind_of(lv: int, ch: String) -> String:
	return THINGS[lv - 1].get(ch, {}).get("kind", "")


## A thing's key in the quest values: level and letter, e.g. "2W".
static func key(lv: int, ch: String) -> String:
	return "%d%s" % [lv, ch]


## Whether a gate, group, trap or person no longer stands in the way (or has been read).
static func cleared(lv: int, ch: String, cell := Vector2i.ZERO) -> bool:
	var q := func(k: String) -> String: return LehanQuests.get_q(k)
	match kind_of(lv, ch):
		"cart": return q.call("m_cart") != ""
		"secret": return q.call("m_secret") != ""
		"air": return q.call("m_air") != ""
		"door": return q.call("m_stores") != ""
		"water": return q.call("m_water") == "drained"
		"ward": return q.call("m_ward") == "open"
		"group": return q.call("m_grp_" + key(lv, ch)) != ""
		"trap": return q.call("m_trap_" + key(lv, ch)) != ""
		"note": return q.call("m_note_" + key(lv, ch)) != ""
		"breach": return q.call("m_breach") != ""
		"npc": return (q.call("m_survivors") == "out") if ch == "S" else (q.call("m_saelen") == "home")
		"chest": return q.call("m_chest_" + key(lv, ch)) != ""
		"vein": return q.call("m_vein_%d_%d" % [cell.x, cell.y]) != ""
	return false


## Whether a square can be stood on (for loading a save and arriving on a level).
static func walkable(lv: int, cell: Vector2i) -> bool:
	var ch := char_at(lv, cell)
	if ch == "#":
		return false
	var k := kind_of(lv, ch)
	if k in SOLID:
		return k == "npc" and cleared(lv, ch)
	if k in GATES:
		return cleared(lv, ch)
	return true


## Where you come out on a level next to one of its things (the first free square beside it),
## facing away from it: [cell, facing], or [] if there is no free square.
static func arrive_near(lv: int, ch: String) -> Array:
	for y in MAPS[lv - 1].size():
		var x := _row(lv, y).find(ch)
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


## What is in a square: {"kind", "ch", "key", "cell"} for a thing that is still there, {"kind":
## "wall"} for rock (and for a secret not yet found), {} for open passage.
func thing_at(cell: Vector2i) -> Dictionary:
	var ch := _char(cell)
	if ch == "#":
		return {"kind": "wall"}
	if ch == ".":
		return {}
	var k := kind_of(level, ch)
	if k == "":
		return {}
	var gone := cleared(level, ch, cell)
	if gone and (k in GATES or k in ["group", "trap", "note", "breach", "npc"]):
		return {}
	var t := {"kind": k, "ch": ch, "key": key(level, ch), "cell": cell, "done": gone}
	if k == "secret":
		t["looks"] = "wall"
	return t


func ahead() -> Vector2i:
	return pos + Game.DIR_VEC[facing]


# ---------------------------------------------------------------- the 3D view

## Built like the walls: rock, a secret not yet found, and the things set into the rock.
func _rocky(cell: Vector2i) -> bool:
	var ch := _char(cell)
	if ch == "#":
		return true
	var k := kind_of(level, ch)
	return k in IN_ROCK or (k == "secret" and not cleared(level, ch))


func build(root: Node3D, cam: Camera3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = [Color(0.32, 0.27, 0.22), Color(0.3, 0.29, 0.27), Color(0.2, 0.22, 0.3)][level - 1]
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.015, 0.01)
	env.fog_density = 0.12
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var wall_tex: String = ["mine_rock", "dig_rock", "jail_stone"][level - 1]
	var mats := {
		"wall": _mat(wall_tex, Color(1.0, 0.95, 0.9)),
		"timber": _mat("mine_timber", Color(1.0, 0.95, 0.9)),
		"vein": _mat("ore_vein", Color.WHITE),
		"tomb": _mat("tomb_gate", Color.WHITE),
		"1": _mat("ward_chain", Color.WHITE), "2": _mat("ward_eye", Color.WHITE), "3": _mat("ward_seal", Color.WHITE),
		"words": _mat("ward_words", Color.WHITE),
	}
	var surf := {}
	for k in mats:
		surf[k] = _st()
	var floors := _st()
	var ceils := _st()
	var h := DungeonView.CELL / 2.0
	var cs := DungeonView.CELL
	var sz := size()
	for y in sz.y:
		for x in sz.x:
			var cell := Vector2i(x, y)
			if _rocky(cell):
				continue
			var c := Vector3(x * cs, 0, y * cs)
			_quad(floors, c, Vector3.UP, Vector3.FORWARD, h, h)
			_quad(ceils, c + Vector3(0, cs, 0), Vector3.DOWN, Vector3.BACK, h, h)
			for d in 4:
				var n: Vector2i = cell + Game.DIR_VEC[d]
				if not _rocky(n):
					continue
				var dv := Vector3(Game.DIR_VEC[d].x, 0, Game.DIR_VEC[d].y)
				var nch := _char(n)
				var which := "wall"
				match kind_of(level, nch):
					"vein": which = "wall" if cleared(level, nch, n) else "vein"
					"tomb": which = "tomb"
					"pillar": which = nch
					"words": which = "words"
				if which == "wall" and level == 1 and (x * 7 + y * 3 + d) % 3 == 0:
					which = "timber"
				_quad(surf[which], c + dv * h + Vector3(0, h, 0), -dv, Vector3.UP, h, h)
	for k in mats:
		_add(root, surf[k], mats[k])
	_add(root, floors, _mat(["mine_floor", "dig_floor", "jail_floor"][level - 1], Color(0.9, 0.86, 0.82)))
	_add(root, ceils, _mat(["rock", "rock", "jail_stone"][level - 1], Color(0.55, 0.5, 0.48)))

	for y in sz.y:
		for x in sz.x:
			var cell := Vector2i(x, y)
			var ch := _char(cell)
			var k := kind_of(level, ch)
			if k == "":
				continue
			var at := Vector3(x * cs, 0, y * cs)
			var done := cleared(level, ch, cell)
			match k:
				"exit": _exit(root, cell)
				"down": _hole(root, at, true)
				"up": _hole(root, at, false)
				"lift": _lift(root, at, LehanQuests.get_q("m_lift") != "")
				"camp": _camp(root, at)
				"chest": _chest(root, at, done)
				"lever": _lever(root, at, ch)
				"water": _water(root, at, done)
				"warden": _warden(root, at)
				"breach": _breach(root, at)
			if done:
				continue
			match k:
				"cart": _cart(root, at)
				"door": _door(root, cell)
				"air": _haze(root, at, Color(0.6, 0.62, 0.45, 0.09))
				"ward": _ward_door(root, cell)
				"npc": _figure(root, at, MinesQuest.figure(ch))
				"group":
					if level == 3:
						_bones(root, at, 3)
				"note":
					if level == 2:
						_bones(root, at, 1)

	_icicles(root)

	var torch := OmniLight3D.new()
	torch.light_color = Color(1.0, 0.78, 0.5)
	torch.light_energy = 2.2
	torch.omni_range = 9.0
	torch.omni_attenuation = 1.4
	torch.position = Vector3(0.15, 0.1, 0.1)
	cam.add_child(torch)
	var flicker := torch.create_tween().set_loops()
	flicker.tween_property(torch, "light_energy", 1.95, 0.23)
	flicker.tween_property(torch, "light_energy", 2.25, 0.31)
	flicker.tween_property(torch, "light_energy", 2.05, 0.19)


# ---------------------------------------------------------------- props

func _exit(root: Node3D, cell: Vector2i) -> void:
	# Daylight at the mouth of the mines.
	var h := DungeonView.CELL / 2.0
	var c := Vector3(cell.x * DungeonView.CELL, 0, cell.y * DungeonView.CELL)
	var sky := StandardMaterial3D.new()
	sky.albedo_texture = Ui.tex("SKY")
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky.disable_fog = true
	var st := _st()
	_quad(st, c + Vector3(0, h, h - 0.01), Vector3.FORWARD, Vector3.UP, h, h)
	_add(root, st, sky)
	var day := OmniLight3D.new()
	day.light_color = Color(0.7, 0.8, 1.0)
	day.light_energy = 1.2
	day.omni_range = 4.0
	day.position = c + Vector3(0, 1.2, -0.8)
	root.add_child(day)


## A shaft with a ladder: down (a hole in the floor) or up (a hole in the roof).
func _hole(root: Node3D, at: Vector3, down: bool) -> void:
	var dark := _plain(Color(0.02, 0.02, 0.02))
	var wood := _plain(Color("#6a4a2a"))
	var y := 0.01 if down else DungeonView.CELL - 0.01
	_box(root, at + Vector3(0, y, 0), Vector3(1.2, 0.02, 1.2), dark)
	var top := 1.2 if down else DungeonView.CELL
	var bottom := -0.2 if down else 0.0
	for s in [-1, 1]:
		_box(root, at + Vector3(s * 0.3, (top + bottom) / 2.0, 0), Vector3(0.07, top - bottom, 0.07), wood)
	var n := 6
	for i in n:
		_box(root, at + Vector3(0, bottom + 0.15 + i * (top - bottom - 0.2) / n, 0), Vector3(0.6, 0.05, 0.06), wood)


func _lift(root: Node3D, at: Vector3, working: bool) -> void:
	var iron := _plain(Color("#4a4a50"))
	var wood := _plain(Color("#6a4a2a"))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_box(root, at + Vector3(sx * 0.55, 1.0, sz * 0.55), Vector3(0.08, 2.0, 0.08), iron)
	_box(root, at + Vector3(0, 0.05, 0), Vector3(1.2, 0.1, 1.2), wood)
	_box(root, at + Vector3(0, 1.95, 0), Vector3(1.2, 0.08, 1.2), iron)
	_box(root, at + Vector3(0, 1.0, 0), Vector3(0.03, 2.0, 0.03), _plain(Color("#a08a60")))
	if not working:
		_box(root, at + Vector3(0.2, 0.4, 0.2), Vector3(0.5, 0.06, 0.08), wood, Vector3(0, 0.4, 0.5))


func _camp(root: Node3D, at: Vector3) -> void:
	var stone := _plain(Color("#5a5450"))
	for i in 8:
		var a := TAU * i / 8.0
		_box(root, at + Vector3(cos(a) * 0.35, 0.06, sin(a) * 0.35), Vector3(0.14, 0.12, 0.14), stone, Vector3(0, a, 0))
	_box(root, at + Vector3(0, 0.03, 0), Vector3(0.45, 0.04, 0.45), _plain(Color("#2a2420")))
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.5, 0.25)
	glow.light_energy = 0.5
	glow.omni_range = 2.5
	glow.position = at + Vector3(0, 0.3, 0)
	root.add_child(glow)


func _chest(root: Node3D, at: Vector3, open: bool) -> void:
	var wood := _plain(Color("#6a4424"))
	var band := _plain(Color("#3a3a3e"))
	_box(root, at + Vector3(0, 0.22, 0), Vector3(0.7, 0.44, 0.45), wood)
	_box(root, at + Vector3(0, 0.22, 0), Vector3(0.72, 0.06, 0.47), band)
	if open:
		_box(root, at + Vector3(0, 0.6, -0.26), Vector3(0.7, 0.4, 0.06), wood, Vector3(-0.3, 0, 0))
	else:
		_box(root, at + Vector3(0, 0.5, 0), Vector3(0.7, 0.12, 0.45), wood)


func _lever(root: Node3D, at: Vector3, ch: String) -> void:
	var iron := _plain(Color("#4a4a50"))
	_box(root, at + Vector3(0, 0.5, 0), Vector3(0.25, 1.0, 0.25), _plain(Color("#5a4a3a")))
	var pulled: bool = MinesQuest.lever_down(ch)
	_box(root, at + Vector3(0, 1.1, 0), Vector3(0.06, 0.6, 0.06), iron, Vector3(0.7 if pulled else -0.7, 0, 0))


func _cart(root: Node3D, at: Vector3) -> void:
	var iron := _plain(Color("#4a4440"))
	_box(root, at + Vector3(0, 0.55, 0), Vector3(1.0, 0.6, 0.8), _plain(Color("#5a4632")))
	_box(root, at + Vector3(0, 0.88, 0), Vector3(0.9, 0.1, 0.7), _plain(Color("#3a3634")))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_box(root, at + Vector3(sx * 0.35, 0.18, sz * 0.42), Vector3(0.3, 0.3, 0.06), iron)
	for sz in [-0.42, 0.42]:
		_box(root, at + Vector3(0, 0.02, sz), Vector3(2.0, 0.04, 0.06), iron)


## A closed door across a passage, facing the way the passage runs.
func _door(root: Node3D, cell: Vector2i) -> void:
	var at := Vector3(cell.x * DungeonView.CELL, 0, cell.y * DungeonView.CELL)
	var ns := _rocky(cell + Vector2i(1, 0)) and _rocky(cell + Vector2i(-1, 0))
	var m := _mat("mine_door", Color.WHITE)
	_box(root, at + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 0.12) if ns else Vector3(0.12, 2.0, 2.0), m)


func _ward_door(root: Node3D, cell: Vector2i) -> void:
	var at := Vector3(cell.x * DungeonView.CELL, 0, cell.y * DungeonView.CELL)
	var ns := _rocky(cell + Vector2i(1, 0)) and _rocky(cell + Vector2i(-1, 0))
	var m := _mat("ward_words", Color(0.8, 0.85, 1.0))
	m.emission_enabled = true
	m.emission = Color(0.1, 0.15, 0.3)
	_box(root, at + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 0.3) if ns else Vector3(0.3, 2.0, 2.0), m)


func _haze(root: Node3D, at: Vector3, col: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 3:
		_box(root, at + Vector3(0, 0.5 + i * 0.45, 0), Vector3(1.96, 0.42, 1.96), m)


func _water(root: Node3D, at: Vector3, drained: bool) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.2, 0.26, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.3
	m.roughness = 0.15
	_box(root, at + Vector3(0, 0.04 if drained else 1.5, 0), Vector3(2.0, 0.04, 2.0), m)


func _figure(root: Node3D, at: Vector3, who: Dictionary) -> void:
	if who.is_empty():
		return
	var sp := Sprite3D.new()
	sp.texture = FigureArt.texture_for(root, who.race, who.look)
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	var height: float = who.get("height", 1.7)
	sp.pixel_size = height / 256.0 * (128.0 / 122.0)
	sp.position = at + Vector3(0, height / 2.0 * (128.0 / 122.0) - 0.04, 0)
	root.add_child(sp)


## The Warden: a tall armoured shape before the tomb gate, with two cold points of light.
func _warden(root: Node3D, at: Vector3) -> void:
	var plate := _plain(Color("#30343e"))
	plate.metallic = 0.6
	plate.roughness = 0.4
	_box(root, at + Vector3(0, 0.55, 0), Vector3(0.7, 1.1, 0.45), plate)
	_box(root, at + Vector3(0, 1.45, 0), Vector3(0.95, 0.75, 0.5), plate)
	_box(root, at + Vector3(0, 2.0, 0), Vector3(0.42, 0.42, 0.42), plate)
	_box(root, at + Vector3(0.62, 1.0, 0.1), Vector3(0.1, 2.0, 0.1), _plain(Color("#8a8e98")))
	var gate := OmniLight3D.new()   # a cold glow on the tomb gate behind it
	gate.light_color = Color(0.45, 0.55, 0.8)
	gate.light_energy = 1.0
	gate.omni_range = 2.6
	gate.position = at + Vector3(0, 1.6, -0.6)
	root.add_child(gate)
	var eyes := OmniLight3D.new()
	eyes.light_color = Color(0.5, 0.75, 1.0)
	eyes.light_energy = 1.4
	eyes.omni_range = 3.5
	eyes.position = at + Vector3(0, 2.0, 0.4)
	root.add_child(eyes)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.6, 0.85, 1.0)
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for sx in [-0.1, 0.1]:
		_box(root, at + Vector3(sx, 2.03, 0.22), Vector3(0.06, 0.04, 0.02), glow)


## The breach: the broken wall, rubble, and the dead.
func _breach(root: Node3D, at: Vector3) -> void:
	var stone := _plain(Color("#6a625a"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 10:
		var s := rng.randf_range(0.2, 0.5)
		_box(root, at + Vector3(rng.randf_range(-0.8, 0.8), s * 0.35, rng.randf_range(-0.8, 0.8)),
			Vector3(s, s * 0.7, s), stone, Vector3(rng.randf(), rng.randf() * TAU, rng.randf()))
	var cloth := _plain(Color("#4a3a2a"))
	_box(root, at + Vector3(-0.3, 0.12, 0.3), Vector3(0.45, 0.2, 1.2), cloth, Vector3(0, 0.5, 0))
	_box(root, at + Vector3(0.5, 0.12, -0.2), Vector3(0.45, 0.2, 1.1), _plain(Color("#3a3a4a")), Vector3(0, -0.9, 0))


func _bones(root: Node3D, at: Vector3, n: int) -> void:
	var bone := _plain(Color("#c8c0a8"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 13 + at.z * 7)
	for i in n * 3:
		_box(root, at + Vector3(rng.randf_range(-0.7, 0.7), 0.03, rng.randf_range(-0.7, 0.7)),
			Vector3(0.35, 0.05, 0.06), bone, Vector3(0, rng.randf() * TAU, 0))


## Mineral threads (helictites) hanging from the ceiling here and there: thin, twisting crystal
## strands that branch and curl like a spider's legs, mostly along the walls and in corners where water
## seeps through the rock. Plenty in the old workings, a few in the new diggings (the rock is freshly
## cut), and fine white lime threads in the old sealed galleries. Placed from the square's coordinates,
## so they are the same every visit. Every strand segment is one instance of a single MultiMesh.
func _icicles(root: Node3D) -> void:
	var chance: float = [0.55, 0.35, 0.25][level - 1]
	var base: Color = [Color(0.7, 0.62, 0.5), Color(0.72, 0.75, 0.78), Color(0.9, 0.88, 0.82)][level - 1]
	var segs := []   # [from, to, radius, colour]
	var cs := DungeonView.CELL
	var sz := size()
	for y in sz.y:
		for x in sz.x:
			var cell := Vector2i(x, y)
			if _rocky(cell):
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = x * 7919 + y * 104729 + level * 31
			if rng.randf() > chance:
				continue
			# Grow beside a wall of the square (a corridor: either side), not in the middle.
			var sides := []
			for d in 4:
				if _rocky(cell + Game.DIR_VEC[d]):
					sides.append(Vector2(Game.DIR_VEC[d]))
			var lean := Vector2.ZERO
			if not sides.is_empty():
				lean = sides[rng.randi() % sides.size()] * 0.7
			for f in rng.randi_range(1, 3):
				var off := (lean + Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))).clamp(Vector2(-0.92, -0.92), Vector2(0.92, 0.92))
				var col := base.darkened(rng.randf_range(0.0, 0.2))
				_strand(segs, rng, Vector3(x * cs + off.x, cs, y * cs + off.y), Vector3.DOWN,
					rng.randf_range(0.25, 0.6), 0.018 if level < 3 else 0.01, col, 0)
	if segs.is_empty():
		return
	var rod := CylinderMesh.new()
	rod.top_radius = 1.0
	rod.bottom_radius = 1.0
	rod.height = 1.0
	rod.radial_segments = 4
	rod.rings = 1
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.3
	m.metallic_specular = 0.8
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = rod
	mm.instance_count = segs.size()
	for i in segs.size():
		var sg: Array = segs[i]
		var a: Vector3 = sg[0]
		var d: Vector3 = sg[1] - a
		var up := d.normalized()
		var side := up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
		var fwd := side.cross(up)
		var r: float = sg[2]
		mm.set_instance_transform(i, Transform3D(Basis(side * r, up * d.length(), fwd * r), a + d / 2.0))
		mm.set_instance_color(i, sg[3])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	root.add_child(mmi)


## One strand: short segments in a wandering direction, thinning as it goes; the first strand mostly
## hangs down, its branches curl off sideways and even upward, as helictites do.
func _strand(segs: Array, rng: RandomNumberGenerator, at: Vector3, dir: Vector3, length: float,
		r: float, col: Color, depth: int) -> void:
	var p := at
	var d := dir
	var left := length
	while left > 0.0 and r > 0.003:
		var step := minf(left, rng.randf_range(0.04, 0.08))
		d = (d + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.35, 0.25), rng.randf_range(-0.6, 0.6))).normalized()
		if depth == 0:
			d = (d + Vector3.DOWN * 0.6).normalized()
		var q := p + d * step
		q.y = minf(q.y, DungeonView.CELL - 0.01)
		segs.append([p, q, r, col])
		p = q
		left -= step
		r *= 0.93
		if depth < 2 and rng.randf() < 0.22:
			var out := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.5), rng.randf_range(-1, 1)).normalized()
			_strand(segs, rng, p, out, left * rng.randf_range(0.4, 0.8), r * 0.75, col.lightened(0.08), depth + 1)


# ---------------------------------------------------------------- building blocks

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
