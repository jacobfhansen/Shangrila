extends Control
## Prologue: "Dawn at the shrine". The spirit wakes (eyelids opening on the camp), listens to
## the Harrow Company's morning chatter, chooses whom to hold on to, and makes its first choice
## through that host. Text lives in scripts/data/prologue.gd.
##
## Controls: the scene moves on by itself; click, Space or Enter hurries it. The mouse wheel
## (or H) opens the history and pauses; scroll past the end, click or Space to resume.
## P pauses and resumes. 1-9 picks a reply.

const P = preload("res://scripts/data/prologue.gd")
const INNER := Color("#c8b8f0")
const SPIRIT := Color("#e8d8a0")
const TAG := Color("#e8c46a")
const NARR := Color("#e0d4b4")

var host := ""
var steps: Array = []
var idx := -1
var choosing := ""      # "", "host" or "reply"
var finished := false
var paused := false
var chosen := -1
var history: Array = []  # [bbcode line, ...]

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
var log_panel: Control
var log_text: RichTextLabel


func _ready() -> void:
	var base: SystemFont = Game.main.theme.default_font
	italic = base.duplicate()
	italic.font_italic = true
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_next)
	add_child(timer)
	_build()
	steps = P.INTRO.duplicate()
	_next()


func _build() -> void:
	Ui.stone_background(self, 0.6)
	painting = ScenePainting.new()
	add_child(painting)
	Ui.place(painting, Rect2(8, 8, 624, 150))
	Ui.frame(self, Rect2(6, 6, 628, 154), Color(0, 0, 0, 0), Color("#a07a40"), 2)

	Ui.frame(self, Rect2(8, 166, 624, 106))
	line_portrait = RacePortrait.new()
	line_portrait.visible = false
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
	Ui.place(replies, Rect2(8, 278, 624, 166))
	prompt = Ui.label(self, "", Vector2(250, 452), 12, Ui.DIM, 376, HORIZONTAL_ALIGNMENT_RIGHT)

	# The history: covers the dialogue area while open.
	log_panel = Ui.frame(self, Rect2(8, 166, 624, 306), Color(0.06, 0.04, 0.02, 0.97), Color("#a07a40"), 2)
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	log_panel.visible = false
	Ui.label(log_panel, "History (paused)", Vector2(12, 6), 14, Ui.GOLD)
	Ui.label(log_panel, "Scroll down, click or Space to resume", Vector2(250, 8), 12, Ui.DIM, 362, HORIZONTAL_ALIGNMENT_RIGHT)
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_active = true
	log_text.scroll_following = false
	log_text.add_theme_font_override("italics_font", italic)
	log_text.add_theme_color_override("default_color", Ui.TEXT)
	log_text.add_theme_font_size_override("normal_font_size", 13)
	log_text.add_theme_font_size_override("italics_font_size", 13)
	log_text.add_theme_constant_override("paragraph_separation", 6)
	log_panel.add_child(log_text)
	Ui.place(log_text, Rect2(12, 30, 600, 268))
	log_text.gui_input.connect(_on_log_input)
	log_panel.gui_input.connect(_on_log_input)


# ---------------------------------------------------------------- stepping through the scene

func _next() -> void:
	if choosing != "" or finished or paused:
		return
	idx += 1
	if idx >= steps.size():
		return
	var st: Dictionary = steps[idx]
	timer.stop()
	if st.has("fx"):
		if st.fx == "eyes":
			_eyes_fx()
			timer.start(5.2)
		else:
			_touch_fx()
			timer.start(1.4)
		return
	if st.has("host_choice"):
		_show_host_choice()
		return
	if st.has("choice"):
		_show_reply_choice()
		return
	if st.has("end"):
		_show_end()
		return
	_show_line(st)
	var text: String = st.get("t", st.get("n", st.get("i", st.get("sp", ""))))
	timer.start(1.8 + text.length() / 24.0)
	prompt.text = "Click or Space to continue  ·  Mouse wheel: history  ·  P: pause"


func _show_line(st: Dictionary) -> void:
	aside_label.text = ""
	if st.has("s"):
		var who: Dictionary = P.CAST[st.s]
		line_portrait.visible = true
		line_portrait.race = who.race
		line_portrait.look = who.look
		line_portrait.highlight = st.s == host
		name_label.text = who.name
		if st.has("a"):
			aside_label.text = "(%s)" % st.a
		_text(Rect2(90, 194, 532, 74), "“%s”" % st.t, Ui.TEXT, false)
		var aside: String = " [i](%s)[/i]" % st.a if st.has("a") else ""
		_log("[color=#%s]%s[/color]%s: “%s”" % [Ui.GOLD.to_html(false), who.name, aside, st.t])
	elif st.has("i"):
		var me: Dictionary = P.CAST[host]
		line_portrait.visible = true
		line_portrait.race = me.race
		line_portrait.look = me.look
		line_portrait.highlight = true
		name_label.text = me.name
		_text(Rect2(90, 194, 532, 74), st.i, INNER, true)
		_log("[color=#%s][i]%s[/i][/color]" % [INNER.to_html(false), st.i])
	elif st.has("sp"):
		# The spirit itself, before it has a host: no face, no name.
		line_portrait.visible = false
		name_label.text = ""
		_text(Rect2(22, 186, 600, 80), st.sp, SPIRIT, true)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_log("[center][color=#%s][i]%s[/i][/color][/center]" % [SPIRIT.to_html(false), st.sp])
		return
	else:
		line_portrait.visible = false
		name_label.text = ""
		_text(Rect2(22, 178, 600, 90), st.n, NARR, false)
		_log("[color=#%s]%s[/color]" % [NARR.to_html(false), st.n])
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _text(r: Rect2, t: String, col: Color, is_italic: bool) -> void:
	text_label.text = t
	text_label.add_theme_color_override("font_color", col)
	if is_italic:
		text_label.add_theme_font_override("font", italic)
	else:
		text_label.remove_theme_font_override("font")
	Ui.place(text_label, r)


func _log(bb: String) -> void:
	history.append(bb)


# ---------------------------------------------------------------- effects

## Eyelids opening on the scene: a few heavy flutters, then wide open.
func _eyes_fx() -> void:
	prompt.text = ""
	var lids := Eyelids.new()
	add_child(lids)
	Ui.place(lids, Rect2(0, 0, 640, 480))
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(lids, "open", 0.10, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lids, "open", 0.02, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lids, "open", 0.28, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lids, "open", 0.16, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lids, "open", 1.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(lids.queue_free)


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
	_log("[center][color=#%s]* * *[/color][/center]" % SPIRIT.to_html(false))


# ---------------------------------------------------------------- choices

func _clear_choices() -> void:
	for ch in replies.get_children():
		ch.queue_free()
	for ch in speak_row.get_children():
		ch.queue_free()


## The spirit chooses whom to hold on to.
func _show_host_choice() -> void:
	choosing = "host"
	prompt.text = "Choose whom to hold on to (1-5)"
	_clear_choices()
	var y := 0.0
	for i in P.ORDER.size():
		var key: String = P.ORDER[i]
		var who: Dictionary = P.CAST[key]
		var bb := "%d. [color=#%s]%s[/color], %s %s.  [i]%s[/i]" % [i + 1, Ui.GOLD.to_html(false), who.name,
			who.race, who.cls, P.SEEN_AS[key]]
		var b := _reply_button(bb, 40)
		var pic := RacePortrait.new()
		pic.race = who.race
		pic.look = who.look
		b.add_child(pic)
		Ui.place(pic, Rect2(4, 2, b.size.y - 4, b.size.y - 4))
		b.tooltip_text = who.blurb
		b.pressed.connect(pick_host.bind(key))
		b.position = Vector2(0, y)
		y += b.size.y + 3


func pick_host(key: String) -> void:
	if choosing != "host":
		return
	choosing = ""
	host = key
	_clear_choices()
	_log("[center][color=#%s][i]The spirit takes hold of %s.[/i][/color][/center]" % [SPIRIT.to_html(false), P.CAST[key].name])
	var rest: Array = P.TOUCH.duplicate()
	for t in P.HOSTS[host].inner:
		rest.append({"i": t})
	rest.append({"choice": true})
	steps = steps.slice(0, idx + 1) + rest
	_next()


func _show_speakers() -> void:
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


func _show_reply_choice() -> void:
	choosing = "reply"
	prompt.text = "Choose a reply (1-4)  ·  Mouse wheel: history"
	_clear_choices()
	_show_speakers()
	var y := 34.0
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
		var b := _reply_button(bb, 8)
		b.pressed.connect(choose.bind(i))
		b.position = Vector2(0, y)
		y += b.size.y + 4


func _reply_button(bb: String, indent: float) -> Button:
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
	var w := 616.0 - indent
	b.add_child(rt)
	replies.add_child(b)
	# Measure the wrapped text to size the button.
	var f: Font = Game.main.theme.default_font
	var h := f.get_multiline_string_size(rt.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, w, 13).y
	h = maxf(h, 18.0)
	b.size = Vector2(624, h + 10)
	rt.position = Vector2(indent, 5)
	rt.size = Vector2(w, h + 2)
	return b


func choose(i: int) -> void:
	if choosing != "reply":
		return
	choosing = ""
	chosen = i
	var rep: Dictionary = P.HOSTS[host].replies[i]
	_clear_choices()
	var rest := []
	if not rep.get("silent", false):
		rest.append({"s": host, "t": rep.t})
	else:
		_log("[i]%s[/i]" % rep.t)
	rest.append_array(rep.after)
	rest.append({"n": "The Harrow Company sets off down the road to Lehan. Inside one of them, something very old is learning to see."})
	rest.append({"end": true})
	steps = steps.slice(0, idx + 1) + rest
	_next()


func _show_end() -> void:
	finished = true
	prompt.text = "Mouse wheel: history"
	if get_meta("args", {}).get("new_game", false):
		Ui.btn(replies, "Continue", Rect2(242, 60, 140, 34), _on_continue, "Set out for Lehan")
		return
	Ui.label(replies, "End of the prologue.", Vector2(0, 30), 15, Ui.GOLD, 624, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.btn(replies, "Play it again", Rect2(160, 80, 140, 34), func(): Game.main.goto("prologue"))
	Ui.btn(replies, "Main menu", Rect2(330, 80, 140, 34), _on_back)


func _on_continue() -> void:
	Game.start_company(host, chosen)
	Game.main.goto("world")


# ---------------------------------------------------------------- pause and history

func set_paused(on: bool) -> void:
	paused = on
	if on:
		timer.paused = true
	else:
		timer.paused = false
		if timer.is_stopped() and choosing == "" and not finished:
			timer.start(0.6)
	if not log_panel.visible:
		prompt.text = "Paused  ·  P or click to resume" if on else ""


func open_history() -> void:
	if log_panel.visible:
		return
	log_text.text = "\n".join(history)
	log_panel.visible = true
	set_paused(true)
	await get_tree().process_frame
	var bar := log_text.get_v_scroll_bar()
	bar.value = bar.max_value


func close_history() -> void:
	if not log_panel.visible:
		return
	log_panel.visible = false
	set_paused(false)
	if choosing == "host":
		prompt.text = "Choose whom to hold on to (1-5)"
	elif choosing == "reply":
		prompt.text = "Choose a reply (1-4)  ·  Mouse wheel: history"


func _at_bottom() -> bool:
	var bar := log_text.get_v_scroll_bar()
	return bar.value >= bar.max_value - bar.page - 2.0


func _on_log_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_DOWN and _at_bottom():
			close_history()
			accept_event()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			close_history()
			accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if Game.main.modal_open:
		return
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and not history.is_empty():
			open_history()
		elif e.button_index == MOUSE_BUTTON_LEFT and not log_panel.visible:
			if paused:
				set_paused(false)
			else:
				_next()
		else:
			return
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			if log_panel.visible:
				close_history()
			else:
				_on_back()
		elif log_panel.visible:
			if e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_H]:
				close_history()
			else:
				return
		elif e.keycode == KEY_H:
			open_history()
		elif e.keycode == KEY_P:
			set_paused(not paused)
		elif choosing != "" and e.keycode >= KEY_1 and e.keycode <= KEY_9:
			var n: int = e.keycode - KEY_1
			if choosing == "host" and n < P.ORDER.size():
				pick_host(P.ORDER[n])
			elif choosing == "reply" and n < P.HOSTS[host].replies.size():
				choose(n)
		elif e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			if paused:
				set_paused(false)
			else:
				_next()
		else:
			return
		get_viewport().set_input_as_handled()


## For the developer tour: run ahead to the next choice.
func skip_to_choice() -> void:
	while choosing == "" and not finished and idx < steps.size() - 1:
		_next()


func _on_back() -> void:
	Game.main.goto("title")


## Black eyelids closing over the screen, with an eye-shaped opening in the middle.
class Eyelids extends Control:
	var open := 0.0:
		set(v):
			open = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if open >= 0.999:
			return
		var w := size.x
		var h := size.y
		var c := Vector2(w / 2, 90)   # looking at the scene first
		var rx := w * (0.55 + 0.6 * open)
		var ry := (h + 200) * open
		# The lids, drawn as thin vertical strips (robust at any opening).
		var n := 160
		var sw := w / n
		var edge_top := PackedVector2Array()
		var edge_bottom := PackedVector2Array()
		for i in n + 1:
			var x := sw * i
			var k := clampf((x - c.x) / rx, -1.0, 1.0)
			var dy := ry * sqrt(1.0 - k * k)
			var y0 := c.y - dy
			var y1 := c.y + dy
			if i < n:
				if y0 > 0:
					draw_rect(Rect2(x, 0, sw + 0.5, y0), Color.BLACK)
				if y1 < h:
					draw_rect(Rect2(x, y1, sw + 0.5, h - y1), Color.BLACK)
			edge_top.append(Vector2(x, y0))
			edge_bottom.append(Vector2(x, y1))
		# Soft, dark edges along the lids, and the whole view dim while barely open.
		for k in 4:
			var a := 0.35 - k * 0.08
			var off := Vector2(0, 3 + k * 4)
			var t2 := PackedVector2Array()
			for q in edge_top:
				t2.append(q + off)
			var b2 := PackedVector2Array()
			for q in edge_bottom:
				b2.append(q - off)
			draw_polyline(t2, Color(0, 0, 0, a), 6.0, true)
			draw_polyline(b2, Color(0, 0, 0, a), 6.0, true)
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.7 * (1.0 - open)))


## The dawn scene above the dialogue: sky, hills, road, the camp and the crowned figure.
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
		# The Harrow Company around the fire, as dark shapes against the dawn.
		_figure(Vector2(118, 140), 1.0, "human")     # Joss
		_figure(Vector2(140, 128), 0.95, "human")    # Maera
		_figure(Vector2(208, 142), 1.15, "thuug")    # Ommuk
		_figure(Vector2(232, 130), 0.95, "aeldroe")  # Ithrae
		_figure(Vector2(196, 126), 0.75, "nisk")     # Tikkat
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

	## A small silhouette standing at `feet`.
	func _figure(feet: Vector2, s: float, kind: String) -> void:
		var col := Color("#1e1a18")
		var sway := sin(t * 0.8 + feet.x) * 0.6
		var body_w := 7.0 * s
		var body_h := 18.0 * s
		if kind == "thuug":
			body_w = 10.0 * s
			draw_colored_polygon(_ellipse(feet + Vector2(sway, -body_h * 0.75), body_w + 3, body_h * 0.55), col.lightened(0.08))
		var body := PackedVector2Array([feet + Vector2(-body_w, 0), feet + Vector2(body_w, 0),
			feet + Vector2(body_w * 0.7 + sway, -body_h), feet + Vector2(-body_w * 0.7 + sway, -body_h)])
		var c := col
		if kind == "aeldroe":
			c = Color(0.85, 0.88, 0.95, 0.35)
		draw_colored_polygon(body, c)
		var head := feet + Vector2(sway, -body_h - 4.5 * s)
		draw_circle(head, 4.5 * s, c)
		if kind == "nisk":
			draw_circle(head + Vector2(-3.5, -4) * s, 2.2 * s, c)
			draw_circle(head + Vector2(3.5, -4) * s, 2.2 * s, c)
			draw_colored_polygon(PackedVector2Array([head + Vector2(3, -1) * s, head + Vector2(8, 1.5) * s, head + Vector2(3, 3) * s]), c)

	func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts
