extends Control
## Prologue prototype: "Dawn at the shrine". The player picks the host from the Harrow Company,
## watches the scene play out by itself, and then makes the first choice in a Fallout-style
## dialogue screen. Text lives in scripts/data/prologue.gd.

const P = preload("res://scripts/data/prologue.gd")
const INNER := Color("#c8b8f0")
const TAG := Color("#e8c46a")
const NARR := Color("#e0d4b4")

var host := ""
var steps: Array = []
var idx := -1
var choosing := false
var finished := false

var italic: SystemFont
var painting: ScenePainting
var line_portrait: RacePortrait
var name_label: Label
var aside_label: Label
var text_label: Label
var speak_row: Control
var replies: Control
var prompt: Label
var timer: Timer


func _ready() -> void:
	var base: SystemFont = Game.main.theme.default_font
	italic = base.duplicate()
	italic.font_italic = true
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_next)
	add_child(timer)
	_build_select()


func _clear() -> void:
	for ch in get_children():
		if ch != timer:
			ch.queue_free()


# ---------------------------------------------------------------- choosing the host

func _build_select() -> void:
	_clear()
	host = ""
	Ui.stone_background(self, 0.55)
	Ui.title(self, "Dawn at the Shrine", Vector2(0, 14), 30, 640, HORIZONTAL_ALIGNMENT_CENTER)
	var sub := Ui.label(self, "Five travellers sleep by a dying fire. Something old stirs beneath the shrine.\nWhich of them will it wake inside?",
		Vector2(0, 58), 14, Ui.TEXT, 640, HORIZONTAL_ALIGNMENT_CENTER)
	sub.clip_text = false
	for i in P.ORDER.size():
		var key: String = P.ORDER[i]
		var ch: Dictionary = P.CAST[key]
		var r := Rect2(14 + i * 124, 112, 116, 276)
		Ui.frame(self, r)
		var pic := RacePortrait.new()
		pic.race = ch.race
		pic.look = ch.look
		add_child(pic)
		Ui.place(pic, Rect2(r.position.x + 16, r.position.y + 12, 84, 84))
		Ui.label(self, ch.name, r.position + Vector2(0, 104), 15, Ui.GOLD, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.label(self, "%s %s" % [ch.race, ch.cls], r.position + Vector2(0, 126), 12, Ui.DIM, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		var blurb := Label.new()
		blurb.text = ch.blurb
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blurb.add_theme_font_size_override("font_size", 12)
		blurb.add_theme_color_override("font_color", Ui.TEXT)
		blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.place(blurb, Rect2(r.position.x + 8, r.position.y + 150, r.size.x - 16, 110))
		add_child(blurb)
		var pick := Button.new()
		pick.flat = true
		pick.focus_mode = Control.FOCUS_NONE
		pick.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pick.tooltip_text = "Wake inside %s" % ch.name
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(1, 0.85, 0.5, 0.08)
		hover.border_color = Ui.GOLD
		hover.set_border_width_all(2)
		hover.set_corner_radius_all(3)
		pick.add_theme_stylebox_override("hover", hover)
		pick.add_theme_stylebox_override("pressed", hover)
		pick.pressed.connect(start_scene.bind(key))
		add_child(pick)
		Ui.place(pick, r)
	Ui.btn(self, "Back", Rect2(20, 436, 90, 32), _on_back, "Back to the main menu")
	Ui.label(self, "Prototype of the opening scene and the dialogue screen", Vector2(120, 444), 12, Ui.DIM, 500, HORIZONTAL_ALIGNMENT_RIGHT)


# ---------------------------------------------------------------- the scene

func start_scene(key: String) -> void:
	host = key
	_clear()
	choosing = false
	finished = false
	Ui.stone_background(self, 0.6)
	painting = ScenePainting.new()
	add_child(painting)
	Ui.place(painting, Rect2(8, 8, 624, 150))
	Ui.frame(self, Rect2(6, 6, 628, 154), Color(0, 0, 0, 0), Color("#a07a40"), 2)

	Ui.frame(self, Rect2(8, 166, 624, 106))
	line_portrait = RacePortrait.new()
	add_child(line_portrait)
	Ui.place(line_portrait, Rect2(18, 176, 60, 60))
	name_label = Ui.label(self, "", Vector2(90, 172), 15, Ui.GOLD, 300)
	aside_label = Ui.label(self, "", Vector2(300, 174), 12, Ui.DIM, 320, HORIZONTAL_ALIGNMENT_RIGHT)
	aside_label.add_theme_font_override("font", italic)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)

	speak_row = Control.new()
	speak_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speak_row)
	Ui.place(speak_row, Rect2(8, 278, 624, 30))
	replies = Control.new()
	replies.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(replies)
	Ui.place(replies, Rect2(8, 312, 624, 160))
	prompt = Ui.label(self, "", Vector2(330, 452), 12, Ui.DIM, 296, HORIZONTAL_ALIGNMENT_RIGHT)

	steps = P.SETUP.duplicate()
	for t in P.HOSTS[host].inner:
		steps.append({"i": t})
	steps.append({"choice": true})
	idx = -1
	_next()


func _next() -> void:
	if choosing:
		return
	if finished:
		return
	idx += 1
	if idx >= steps.size():
		return
	var st: Dictionary = steps[idx]
	timer.stop()
	if st.has("fx"):
		_touch_fx()
		timer.start(1.4)
		return
	if st.has("choice"):
		_show_choice()
		return
	if st.has("end"):
		_show_end()
		return
	_show_line(st)
	var text: String = st.get("t", st.get("n", st.get("i", "")))
	timer.start(1.8 + text.length() / 24.0)
	prompt.text = "Click or press Space to continue"


func _show_line(st: Dictionary) -> void:
	aside_label.text = ""
	if st.has("s"):
		var who: Dictionary = P.CAST[st.s]
		line_portrait.visible = true
		line_portrait.race = who.race
		line_portrait.look = who.look
		line_portrait.dim = false
		line_portrait.highlight = st.s == host and idx > _touch_index()
		name_label.text = who.name
		if st.has("a"):
			aside_label.text = "(%s)" % st.a
		_text(Rect2(90, 194, 532, 74), "“%s”" % st.t, Ui.TEXT, false)
	elif st.has("i"):
		var me: Dictionary = P.CAST[host]
		line_portrait.visible = true
		line_portrait.race = me.race
		line_portrait.look = me.look
		line_portrait.dim = false
		line_portrait.highlight = true
		name_label.text = me.name
		_text(Rect2(90, 194, 532, 74), st.i, INNER, true)
	else:
		line_portrait.visible = false
		name_label.text = ""
		_text(Rect2(22, 178, 600, 90), st.n, NARR, false)


func _text(r: Rect2, t: String, col: Color, is_italic: bool) -> void:
	text_label.text = t
	text_label.add_theme_color_override("font_color", col)
	if is_italic:
		text_label.add_theme_font_override("font", italic)
	else:
		text_label.remove_theme_font_override("font")
	Ui.place(text_label, r)


func _touch_index() -> int:
	for i in steps.size():
		if steps[i].has("fx"):
			return i
	return 999


func _touch_fx() -> void:
	prompt.text = ""
	var flash := ColorRect.new()
	flash.color = Color(1, 0.9, 0.6, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	Ui.place(flash, Rect2(0, 0, 640, 480))
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.85, 0.35)
	tw.tween_property(flash, "color:a", 0.0, 1.0)
	tw.tween_callback(flash.queue_free)
	painting.glow = 1.0


func _show_speakers() -> void:
	for ch in speak_row.get_children():
		ch.queue_free()
	Ui.label(speak_row, "Speaking:", Vector2(4, 6), 13, Ui.DIM)
	for i in P.ORDER.size():
		var key: String = P.ORDER[i]
		var who: Dictionary = P.CAST[key]
		var pic := RacePortrait.new()
		pic.race = who.race
		pic.look = who.look
		pic.highlight = key == host
		pic.dim = key != host
		pic.mouse_filter = Control.MOUSE_FILTER_STOP
		pic.tooltip_text = "%s (host)\nThe spirit speaks through them freely." % who.name if key == host \
			else "%s\nThe spirit cannot reach them yet." % who.name
		speak_row.add_child(pic)
		Ui.place(pic, Rect2(80 + i * 34, 0, 28, 28))
	var me: Dictionary = P.CAST[host]
	var known := Ui.label(speak_row, "Known traits: " + ", ".join(me.traits), Vector2(258, 7), 12, Ui.DIM, 362, HORIZONTAL_ALIGNMENT_RIGHT)
	known.tooltip_text = "The spirit lives inside its host, so it knows the host's nature."


func _show_choice() -> void:
	choosing = true
	prompt.text = "Choose a reply (1-4)"
	_show_speakers()
	for ch in replies.get_children():
		ch.queue_free()
	var y := 0.0
	var list: Array = P.HOSTS[host].replies
	for i in list.size():
		var rep: Dictionary = list[i]
		var bb := "%d. " % (i + 1)
		for tag in rep.tags:
			bb += "[color=#%s][%s][/color] " % [TAG.to_html(false), tag]
		if rep.get("silent", false):
			bb += "[i]%s[/i]" % rep.t
		else:
			bb += "“%s”" % rep.t
		var b := _reply_button(bb, i)
		b.position = Vector2(0, y)
		y += b.size.y + 4


func _reply_button(bb: String, i: int) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.07, 0.04, 0.85)
	normal.border_color = Color("#5a4428")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.22, 0.15, 0.08, 0.95)
	hover.border_color = Ui.GOLD
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_override("italics_font", italic)
	rt.add_theme_color_override("default_color", Ui.TEXT)
	rt.add_theme_font_size_override("normal_font_size", 13)
	rt.add_theme_font_size_override("italics_font_size", 13)
	rt.text = bb
	rt.position = Vector2(8, 5)
	rt.size = Vector2(604, 10)
	b.add_child(rt)
	replies.add_child(b)
	# Measure the wrapped text to size the button.
	var f: Font = Game.main.theme.default_font
	var plain := rt.get_parsed_text()
	var h := f.get_multiline_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, 604, 13).y
	b.size = Vector2(624, h + 10)
	rt.size = Vector2(604, h + 2)
	b.pressed.connect(choose.bind(i))
	return b


func choose(i: int) -> void:
	if not choosing:
		return
	choosing = false
	var rep: Dictionary = P.HOSTS[host].replies[i]
	for ch in replies.get_children():
		ch.queue_free()
	for ch in speak_row.get_children():
		ch.queue_free()
	var rest := []
	if not rep.get("silent", false):
		rest.append({"s": host, "t": rep.t})
	rest.append_array(rep.after)
	rest.append({"n": "The Harrow Company sets off down the road to Lehan. Inside one of them, something very old is learning to see."})
	rest.append({"end": true})
	steps = steps.slice(0, idx + 1) + rest
	_next()


func _show_end() -> void:
	finished = true
	prompt.text = ""
	Ui.label(replies, "End of the prologue prototype.", Vector2(0, 20), 15, Ui.GOLD, 624, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.btn(replies, "Choose another host", Rect2(150, 70, 160, 34), _build_select)
	Ui.btn(replies, "Main menu", Rect2(330, 70, 140, 34), _on_back)


func _unhandled_input(e: InputEvent) -> void:
	if host == "" or Game.main.modal_open:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			_on_back()
		elif choosing and e.keycode >= KEY_1 and e.keycode <= KEY_9:
			var n: int = e.keycode - KEY_1
			if n < P.HOSTS[host].replies.size():
				choose(n)
		elif e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_next()
		else:
			return
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_next()


## For the developer tour: jump straight to the first choice.
func skip_to_choice() -> void:
	while not choosing and idx < steps.size() - 1:
		_next()


func _on_back() -> void:
	Game.main.goto("title")


## The dawn scene above the dialogue: sky, hills, road, campfire and the crowned figure.
class ScenePainting extends Control:
	var t := 0.0
	var glow := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Dawn sky.
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 100), Vector2(0, 100)]),
			PackedColorArray([Color("#3e4258"), Color("#4a4a62"), Color("#d8a888"), Color("#c89a88")]))
		# Distant hills.
		var hills := PackedVector2Array([Vector2(0, h)])
		for i in 33:
			var x := w * i / 32.0
			hills.append(Vector2(x, 82 + sin(i * 0.7) * 8 + sin(i * 1.9) * 4))
		hills.append(Vector2(w, h))
		draw_colored_polygon(hills, Color("#55556a"))
		# Ground and road.
		draw_rect(Rect2(0, 100, w, h - 100), Color("#3a3a2a"))
		draw_colored_polygon(PackedVector2Array([Vector2(0, h), Vector2(w * 0.28, h), Vector2(w * 0.62, 100), Vector2(w * 0.56, 100)]), Color("#5a5040"))
		# Campfire with rising smoke.
		var fire := Vector2(170, 136)
		for k in 6:
			var a := fmod(t * 0.35 + k / 6.0, 1.0)
			draw_circle(fire + Vector2(sin(t + k) * 6 * a, -a * 70), 3 + a * 9, Color(0.7, 0.7, 0.72, 0.28 * (1 - a)))
		draw_circle(fire, 10, Color("#3a2010"))
		draw_circle(fire + Vector2(0, -3), 5 + sin(t * 9) * 0.8, Color("#ff9030", 0.9))
		draw_circle(fire + Vector2(1, -6), 2.6, Color("#ffe080"))
		# Brambles around the shrine; half of them hacked away. Drawn 1.7x around its foot.
		var shrine := Vector2.ZERO
		draw_set_transform(Vector2(372, 140), 0.0, Vector2(1.7, 1.7))
		for k in 14:
			var p := shrine + Vector2(-58 + k * 9 + (k % 3) * 3, -10 + (k % 4) * 4)
			if k > 4 and k < 10:
				continue
			draw_circle(p, 9 + (k % 3) * 2, Color("#2a3a22"))
			draw_circle(p + Vector2(-2, -3), 5, Color("#34482a"))
		for k in 5:
			draw_line(shrine + Vector2(-30 + k * 12, 14), shrine + Vector2(-22 + k * 12, 10), Color("#2a3a22"), 2.0)
		# The warm glow, once the spirit has stirred.
		if glow > 0.0:
			var pulse := 0.6 + 0.4 * sin(t * 2.0)
			for r in [44.0, 30.0, 18.0]:
				draw_circle(shrine + Vector2(0, -34), r, Color(1.0, 0.85, 0.5, 0.13 * glow * pulse))
		# The plinth and the worn, crowned figure.
		var stone := Color("#8a887c")
		draw_rect(Rect2(shrine.x - 18, shrine.y - 14, 36, 16), stone.darkened(0.15))
		draw_colored_polygon(PackedVector2Array([shrine + Vector2(-11, -14), shrine + Vector2(11, -14),
			shrine + Vector2(7, -50), shrine + Vector2(-7, -50)]), stone)
		draw_circle(shrine + Vector2(0, -56), 7, stone)
		draw_colored_polygon(PackedVector2Array([shrine + Vector2(-7, -61), shrine + Vector2(-6, -69), shrine + Vector2(-3, -64),
			shrine + Vector2(0, -71), shrine + Vector2(3, -64), shrine + Vector2(6, -69), shrine + Vector2(7, -61)]), stone.darkened(0.1))
		draw_line(shrine + Vector2(-7, -40), shrine + Vector2(7, -36), stone.darkened(0.25), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Drifting mist.
		for k in 4:
			var x := fmod(t * (6 + k * 2) + k * 170, w + 240) - 120
			var y := 96 + k * 13
			draw_colored_polygon(_ellipse(Vector2(x, y), 120, 7), Color(0.92, 0.9, 0.94, 0.16))

	func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts
