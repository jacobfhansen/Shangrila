extends Control
## The old tunnels under Lehan (Skee's quest), walked in first person like the streets (see
## LehanTunnels and SkeeQuest). Walk into the ladder to climb back out to Tanners' Row.
## Keys: W/Up forward, S/Down back, A/Left and D/Right turn, Q/E step sideways, Space use, C party.
## Args: {"at_cell": [x, y], "facing": dir} to stand at a cell (after the tunnels changed).

var area := LehanTunnels.new()
var view: DungeonView
var compass: Compass
var hint: Label
var talking := false
var buttons: Array = []
var came_from: Vector2i   # the cell before the last step (the rats drive you back there)
var stepped := false      # the last move was a step (not a turn, nor arriving here)


func _ready() -> void:
	var args: Dictionary = get_meta("args", {})
	if args.has("at_cell"):
		area.pos = Vector2i(args.at_cell[0], args.at_cell[1])
		area.facing = args.get("facing", 1)
	came_from = area.pos
	Ui.stone_background(self)
	view = DungeonView.new()
	view.area = area
	add_child(view)
	view.moved.connect(_after_move)
	Ui.frame(self, Rect2(14, 14, 412, 412), Color.BLACK, Color("#a07a40"), 4)
	var vr := TextureRect.new()
	vr.texture = view.get_texture()
	vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vr.stretch_mode = TextureRect.STRETCH_SCALE
	vr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vr)
	Ui.place(vr, Rect2(20, 20, 400, 400))

	Ui.title(self, "Below Lehan", Vector2(438, 18), 22, 190, HORIZONTAL_ALIGNMENT_CENTER)
	compass = Compass.new()
	compass.area = area
	add_child(compass)
	Ui.place(compass, Rect2(482, 58, 101, 101))
	var mv := [["↶", 0, 0, _turn.bind(-1), "Turn left (A / Left)"],
		["↑", 1, 0, _walk.bind(0), "Forward (W / Up)"],
		["↷", 2, 0, _turn.bind(1), "Turn right (D / Right)"],
		["←", 0, 1, _walk.bind(3), "Step left (Q)"],
		["↓", 1, 1, _walk.bind(2), "Back (S / Down)"],
		["→", 2, 1, _walk.bind(1), "Step right (E)"]]
	for m in mv:
		var b := Ui.btn(self, m[0], Rect2(476 + m[1] * 39, 168 + m[2] * 38, 35, 34), m[3], m[4])
		b.add_theme_font_size_override("font_size", 18)
		buttons.append(b)
	buttons.append(Ui.btn(self, "Use", Rect2(446, 252, 180, 32), _use_ahead,
		"Look at, or use, what is straight ahead (Space)"))
	buttons.append(Ui.btn(self, "Party", Rect2(446, 290, 88, 30), _on_party, "Your characters: abilities, gear and silver (C)"))
	buttons.append(Ui.btn(self, "Quit", Rect2(538, 290, 88, 30), _on_quit, "Back to the main menu"))
	Ui.frame(self, Rect2(436, 364, 196, 62))
	var help := Ui.label(self, "Cold, damp stone, older than the town above. The ladder leads back up.",
		Vector2(444, 368), 11, Ui.DIM, 182)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size = Vector2(182, 54)
	Ui.frame(self, Rect2(14, 432, 618, 38))
	hint = Ui.label(self, "", Vector2(24, 442), 13, Ui.TEXT, 600)
	_after_move()


func _after_move() -> void:
	compass.queue_redraw()
	var t := area.thing_at(area.ahead())
	hint.text = {"ladder": "Ahead: the ladder up to the tannery.  Walk on or press Space to climb out.",
		"collapse": "Ahead: fallen stone blocks the passage.  Space to look for a way through.",
		"bag": "Ahead: something lying in the passage.  Space to look.",
		}.get(t.get("kind", ""), "A passage of old, fitted stone. Water drips somewhere.")
	if talking or not stepped:
		return
	stepped = false
	# Stepping onto the rats or into the chamber of the lights starts a scene.
	match area.thing_at(area.pos).get("kind", ""):
		"rats":
			_scene.call_deferred("The rats", SkeeQuest.rats(), true)
		"lights":
			_scene.call_deferred("The blue lights", SkeeQuest.lights(), false)


func _walk(dir_rel: int) -> void:
	if _locked():
		return
	var dir: int = posmod(area.facing + dir_rel, 4)
	var target: Vector2i = area.pos + Game.DIR_VEC[dir]
	var from := area.pos
	if view.step(dir):
		came_from = from
		stepped = true
	elif dir_rel == 0:
		_use(area.thing_at(target))


func _turn(d: int) -> void:
	if _locked():
		return
	view.turn(d)


func _locked() -> bool:
	return talking or Game.main.modal_open


func _use_ahead() -> void:
	if _locked() or view.busy:
		return
	_use(area.thing_at(area.ahead()))


func _use(t: Dictionary) -> void:
	match t.get("kind", ""):
		"ladder":
			Game.main.goto("streets", {"at": "tannery"})
		"collapse":
			await _scene("The collapse", SkeeQuest.collapse(), false)
		"bag":
			await _scene("Something in the passage", SkeeQuest.bag(), false)


## A scene in the dialogue window. `retreat`: if the obstacle is still there afterwards, step back
## to where the party came from (the rats drive you off).
func _scene(title: String, lines: Array, retreat: bool) -> void:
	if talking:
		return
	talking = true
	for b in buttons:
		b.disabled = true
	var host: String = Game.story.get("host", "")
	if host == "":
		lines = lines.filter(func(st): return not st.has("i") and not st.has("sp"))
	var before := _state()
	var ov := Control.new()
	add_child(ov)
	Ui.place(ov, Rect2(0, 0, 640, 480))
	Ui.frame(ov, Rect2(10, 150, 620, 322), Color("#1a120a"), Color("#a07a40"), 2)
	Ui.label(ov, title, Vector2(22, 156), 15, Ui.GOLD)
	var box := DialogueBox.new()
	box.cast = MarketData.cast()
	box.host = host
	Ui.place(box, Rect2(20, 180, 600, 286))   # sized before _ready builds it
	ov.add_child(box)
	box.effect.connect(LehanQuests.apply)
	box.play(lines)
	await box.finished
	box.show_buttons([["Go on", func(): box.finished.emit()]])
	await box.finished
	ov.queue_free()
	talking = false
	for b in buttons:
		b.disabled = false
	var stand := area.pos
	if retreat and area.thing_at(area.pos).get("kind", "") == "rats":
		stand = came_from
	if _state() != before or stand != area.pos:
		# Something changed down here (or the rats drove you back): rebuild the view.
		Game.main.goto("tunnels", {"at_cell": [stand.x, stand.y], "facing": area.facing})
	else:
		_after_move()


func _state() -> String:
	return "%s%s%s" % [SkeeQuest.rats_done(), SkeeQuest.collapse_passed(), SkeeQuest.bag_taken()]


func _on_party() -> void:
	if _locked() or Game.party.is_empty():
		return
	Game.main.goto("view", {"party": true, "index": 0, "back": "tunnels",
		"back_args": {"at_cell": [area.pos.x, area.pos.y], "facing": area.facing}})


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


func _unhandled_input(e: InputEvent) -> void:
	if _locked() or not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.keycode:
		KEY_W, KEY_UP: _walk(0)
		KEY_S, KEY_DOWN: _walk(2)
		KEY_A, KEY_LEFT: _turn(-1)
		KEY_D, KEY_RIGHT: _turn(1)
		KEY_Q: _walk(3)
		KEY_E: _walk(1)
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER: _use_ahead()
		KEY_C: _on_party()
		_: return
	get_viewport().set_input_as_handled()
