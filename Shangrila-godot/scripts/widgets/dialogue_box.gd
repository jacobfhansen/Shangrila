class_name DialogueBox
extends Control
## The dialogue window: one line at a time (speaker portrait, name, stage direction, text),
## replies with tags, the "Speaking" row, and a history that can be scrolled back.
##
## Steps are dictionaries:
##   {"n": text}                         narration
##   {"s": who, "t": text, "a": aside}   speech; `who` is a key in `cast`
##   {"i": text}                         inner experience of the host (italics)
##   {"sp": text}                        the spirit's own thought, with no host (centred italics)
##   {"fx": name, "wait": seconds}       emits `effect(name)`, then waits
##   {"choice": id, "options": [...], "prompt": text, "speakers": true}
##       options: {"t", "tags": [], "silent": bool, "portrait": who, "tip": text, "after": [steps],
##                 "checks": [LehanQuests.chk(...)]}   the abilities show on the option (coloured
##                 by the chance: red, orange, yellow, green, grey for a sure thing), the details
##                 (who rolls, skill, bonus, chance) in its tooltip, above the tip
##   {"end": true}                        stop and emit `finished`
##   {"dyn": callable}                    a step worked out only when it is reached (callable returns it)
## Options may carry "ok": whether their check will pass, written to the quest log (not the history);
## a failed one in a quest's scene also emits effect("fail:<quest>").
## Set `journal` (a quest key, see Journal) and `journal_place` to keep the scene in the quest log.
## The scene moves on by itself; click, Space or Enter hurries it. Mouse wheel up (or H) opens the
## history and pauses; scroll down past the end, click or Space resumes. P pauses.

signal effect(name: String)
signal choice_made(id: String, index: int)
signal finished

const INNER := Color("#c8b8f0")
const SPIRIT := Color("#e8d8a0")
const TAG := Color("#e8c46a")
## Skill tags are coloured by the chance of success, on the usual RPG difficulty scale:
## [below this %, colour]; a sure thing is grey.
const ODDS := [[20, Color("#e0503c")], [40, Color("#e8903a")], [70, Color("#f0e050")], [100, Color("#6cc86a")]]
const SURE := Color("#9a9a9a")
const DIFF_NAMES := {6: "easy", 9: "normal", 10: "tricky", 12: "hard"}
const NARR := Color("#e0d4b4")
const LINE_H := 106.0

var cast: Dictionary = {}       # who -> {name, race, look, traits}
var host := ""                  # the spirit's host (highlighted, its traits are known)
var steps: Array = []
var idx := -1
var choosing := ""
var choice_step := {}
var paused := false
var running := false
var history: Array = []
var _queued: Array = []
var journal := ""              # the quest this scene belongs to ("" for none)
var journal_place := ""        # where it happens, the heading in the quest log
var _journal_lines = null      # this scene's lines in the quest log, once it has any

var italic: SystemFont
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


func _build() -> void:
	var w := size.x
	var line_frame := Ui.frame(self, Rect2(0, 0, w, LINE_H))
	line_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE   # clicks reach the box (_gui_input)
	line_portrait = RacePortrait.new()
	line_portrait.visible = false
	add_child(line_portrait)
	Ui.place(line_portrait, Rect2(10, 10, 60, 60))
	name_label = Ui.label(self, "", Vector2(82, 6), 15, Ui.GOLD, 300)
	aside_label = Ui.label(self, "", Vector2(w - 330, 8), 12, Ui.DIM, 320, HORIZONTAL_ALIGNMENT_RIGHT)
	aside_label.add_theme_font_override("font", italic)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)

	speak_row = Control.new()
	speak_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speak_row)
	Ui.place(speak_row, Rect2(0, LINE_H + 6, w, 30))
	replies = Control.new()
	replies.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(replies)
	Ui.place(replies, Rect2(0, LINE_H + 6, w, size.y - LINE_H - 30))
	prompt = Ui.label(self, "", Vector2(w - 406, LINE_H - 20), 11, Ui.DIM, 398, HORIZONTAL_ALIGNMENT_RIGHT)

	log_panel = Ui.frame(self, Rect2(0, 0, w, size.y), Color(0.06, 0.04, 0.02, 0.97), Color("#a07a40"), 2)
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	log_panel.visible = false
	Ui.label(log_panel, "History (paused)", Vector2(12, 6), 14, Ui.GOLD)
	Ui.label(log_panel, "Scroll down, click or Space to resume", Vector2(w - 312, 8), 12, Ui.DIM, 300, HORIZONTAL_ALIGNMENT_RIGHT)
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_active = true
	log_text.add_theme_font_override("italics_font", italic)
	log_text.add_theme_color_override("default_color", Ui.TEXT)
	log_text.add_theme_font_size_override("normal_font_size", 13)
	log_text.add_theme_font_size_override("italics_font_size", 13)
	log_text.add_theme_constant_override("paragraph_separation", 6)
	log_panel.add_child(log_text)
	Ui.place(log_text, Rect2(12, 30, w - 24, size.y - 38))
	log_text.gui_input.connect(_on_log_input)
	log_panel.gui_input.connect(_on_log_input)


# ---------------------------------------------------------------- running steps

## Starts (or continues with) a list of steps. Await `finished` for the end.
func play(list: Array) -> void:
	steps = list.duplicate()
	idx = -1
	running = true
	_clear_choices()
	_next()


## Called from a `choice_made` handler: steps to run right after the chosen option's own.
func queue(list: Array) -> void:
	_queued.append_array(list)


## Adds a line to the history without showing it (e.g. the combat log), and to the quest log if
## the scene belongs to a quest (`extra` goes only there, e.g. whether a check passed).
func log_line(bb: String, extra := "") -> void:
	history.append(bb)
	if journal != "":
		if _journal_lines == null:
			_journal_lines = Journal.begin(journal, journal_place)
		_journal_lines.append(bb + extra)


func _who(key: String) -> Dictionary:
	return cast.get(key, {"name": key.capitalize(), "race": "Human", "look": {}})


func _next() -> void:
	if not running or choosing != "" or paused:
		return
	idx += 1
	timer.stop()
	if idx >= steps.size():
		_finish()
		return
	var st: Dictionary = steps[idx]
	if st.has("dyn"):
		st = st.dyn.call()
		steps[idx] = st
	if st.has("s") and st.s != host and _who(st.s).name in Game.story.get("dead", []):
		_next()   # a companion who has died: their line is gone with them
		return
	if st.has("fx"):
		prompt.text = ""
		effect.emit(st.fx)
		timer.start(st.get("wait", 1.4))
		return
	if st.has("choice"):
		_show_choice(st)
		return
	if st.has("end"):
		_finish()
		return
	_show_line(st)
	var text: String = st.get("t", st.get("n", st.get("i", st.get("sp", ""))))
	timer.start(1.8 + text.length() / 24.0)
	prompt.text = "Click or Space to continue  ·  Mouse wheel: history  ·  P: pause"


func _finish() -> void:
	running = false
	timer.stop()
	prompt.text = "Mouse wheel: history"
	finished.emit()


func _show_line(st: Dictionary) -> void:
	aside_label.text = ""
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if st.has("s"):
		var who := _who(st.s)
		line_portrait.visible = true
		line_portrait.race = who.race
		line_portrait.look = who.look
		line_portrait.highlight = st.s == host
		name_label.text = who.name
		if st.has("a"):
			aside_label.text = "(%s)" % st.a
		_text(Rect2(82, 28, size.x - 92, 56), "“%s”" % st.t, Ui.TEXT, false)
		var aside: String = " [i](%s)[/i]" % st.a if st.has("a") else ""
		log_line("%s[color=#%s]%s[/color]%s: “%s”" % [st.get("mark", ""), Ui.GOLD.to_html(false), who.name, aside, st.t], st.get("extra", ""))
	elif st.has("i"):
		var me := _who(host)
		line_portrait.visible = true
		line_portrait.race = me.race
		line_portrait.look = me.look
		line_portrait.highlight = true
		name_label.text = me.name
		_text(Rect2(82, 28, size.x - 92, 56), st.i, INNER, true)
		log_line("[color=#%s][i]%s[/i][/color]" % [INNER.to_html(false), st.i])
	elif st.has("sp"):
		line_portrait.visible = false
		name_label.text = ""
		_text(Rect2(14, 20, size.x - 28, 64), st.sp, SPIRIT, true)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		log_line("[center][color=#%s][i]%s[/i][/color][/center]" % [SPIRIT.to_html(false), st.sp])
	else:
		line_portrait.visible = false
		name_label.text = ""
		_text(Rect2(14, 12, size.x - 28, 72), st.n, NARR, false)
		log_line("[color=#%s]%s[/color]" % [NARR.to_html(false), st.n])


func _text(r: Rect2, t: String, col: Color, is_italic: bool) -> void:
	text_label.text = t
	text_label.add_theme_color_override("font_color", col)
	if is_italic:
		text_label.add_theme_font_override("font", italic)
	else:
		text_label.remove_theme_font_override("font")
	Ui.place(text_label, r)


# ---------------------------------------------------------------- choices

## How much of the box is in use, from the top: just the line, or down to the last reply or
## button (all of it while the history is open). Lets a screen shrink the panel behind it.
func content_height() -> float:
	if log_panel.visible:
		return size.y
	var bottom := LINE_H
	for ch in replies.get_children():
		if ch is Control and not ch.is_queued_for_deletion() and ch.visible:
			bottom = maxf(bottom, replies.position.y + ch.position.y + ch.size.y)
	for ch in speak_row.get_children():
		if ch is Control and not ch.is_queued_for_deletion() and ch.visible:
			bottom = maxf(bottom, speak_row.position.y + speak_row.size.y)
	return bottom


func _clear_choices() -> void:
	for ch in replies.get_children():
		ch.queue_free()
	for ch in speak_row.get_children():
		ch.queue_free()


func _show_choice(st: Dictionary) -> void:
	choosing = st.choice
	choice_step = st
	var opts: Array = st.options
	prompt.text = st.get("prompt", "Choose a reply (1-%d)" % opts.size()) + "  ·  Mouse wheel: history"
	_clear_choices()
	var y := 0.0
	var sp = st.get("speakers", false)
	if sp is String and sp == "traits":
		_show_known_traits()
		y = 34.0
	elif sp:
		_show_speakers()
		y = 34.0
	for i in opts.size():
		var o: Dictionary = opts[i]
		var bb := "%d. " % (i + 1)
		if o.has("checks"):
			bb += "[color=#%s][%s][/color] " % [_odds_color(_check_chance(o.checks)).to_html(false), _check_label(o.checks)]
		for tag in o.get("tags", []):
			bb += "[color=#%s][%s][/color] " % [TAG.to_html(false), tag]
		if o.has("bb"):
			bb += o.bb
		elif o.get("silent", false):
			bb += "[i]%s[/i]" % o.t
		else:
			bb += "“%s”" % o.t
		var b := _reply_button(bb, 40.0 if o.has("portrait") else 8.0)
		if o.has("portrait"):
			var who := _who(o.portrait)
			var pic := RacePortrait.new()
			pic.race = who.race
			pic.look = who.look
			b.add_child(pic)
			Ui.place(pic, Rect2(4, 2, b.size.y - 4, b.size.y - 4))
		b.tooltip_text = _check_tip(o.checks, o.get("tip", "")) if o.has("checks") else o.get("tip", "")
		b.pressed.connect(choose.bind(i))
		b.position = Vector2(0, y)
		y += b.size.y + 3


## The chance of passing one check, in percent.
static func _one_chance(c: Dictionary) -> int:
	if c.get("needs_skill", false) and Game.ability(c.who, c.ability) <= 0:
		return 0
	return Game.chance(c.who, c.ability, c.diff, c.bonus)


## The chance of passing all of an option's checks (any one of the alternatives will do).
static func _check_chance(checks: Array) -> int:
	var total := 1.0
	for g in _check_groups(checks):
		var miss := 1.0
		for c in g:
			miss *= 1.0 - _one_chance(c) / 100.0
		total *= 1.0 - miss
	return roundi(total * 100)


static func _odds_color(pct: int) -> Color:
	for band in ODDS:
		if pct < band[0]:
			return band[1]
	return SURE


## The checks grouped: each group is a list of alternatives, and every group must be passed.
static func _check_groups(checks: Array) -> Array:
	var groups: Array = []
	for c in checks:
		if c.get("or", false) and not groups.is_empty():
			groups[-1].append(c)
		else:
			groups.append([c])
	return groups


## The abilities an option needs, for its tag: "Talk", "Talk, then Perception or Lore".
static func _check_label(checks: Array) -> String:
	var parts: Array = []
	for g in _check_groups(checks):
		parts.append(" or ".join(g.map(func(c): return Game.ABILITY_NAMES[c.ability])))
	return ", then ".join(parts)


## The tooltip for an option with checks: for each, who rolls, their skill, any bonus and the
## chance; the overall chance when there are several; then the option's own tip.
static func _check_tip(checks: Array, tip: String) -> String:
	var lines: Array = []
	for g in _check_groups(checks):
		for c in g:
			if not lines.is_empty():
				lines.append("")
			var who: Dictionary = c.who
			var ab: String = c.ability
			var nm: String = Game.ABILITY_NAMES[ab]
			var level := Game.ability(who, ab)
			var diff: int = c.diff
			lines.append("%s check (%s: d10 + skill + bonus must reach %d)" % [nm, DIFF_NAMES.get(diff, "normal"), diff])
			var best := level
			for m in Game.party:
				best = maxi(best, Game.ability(m, ab))
			var role := "Rolls"
			if Game.party.size() > 1:
				role = "Best in the party" if level >= best else ("The host" if who == LehanQuests.host_char() else "Rolls")
			lines.append("%s: %s, %s %d" % [role, who.name, nm, level])
			var bonus: int = c.bonus
			var why: String = c.get("why", "")
			if not ", " in why:   # one source: its number is the bonus itself
				var rx := RegEx.create_from_string(" [+-]\\d+$")
				why = rx.sub(why, "")
			if bonus != 0 or why != "":
				lines.append("Bonus %+d%s" % [bonus, ": " + why if why != "" else ""])
			var pct := _one_chance(c)
			if c.get("needs_skill", false) and level <= 0:
				lines.append("Needs at least 1 in %s" % nm)
			lines.append("Chance: %d%%" % pct)
	if checks.size() > 1:
		lines.append("")
		lines.append("Chance overall: %d%%" % _check_chance(checks))
	if tip != "":
		lines.append("")
		lines.append(tip)
	return "\n".join(lines)


## Only what the spirit knows about its host (when the spirit itself is the one speaking).
func _show_known_traits() -> void:
	Ui.frame(speak_row, Rect2(0, -2, size.x, 32), Color(0.08, 0.06, 0.04, 0.92), Color("#5a4428"), 1)
	var me := _who(host)
	var l := Ui.label(speak_row, "The spirit knows %s: %s" % [me.name, ", ".join(me.get("traits", []))], Vector2(10, 7), 13, SPIRIT, size.x - 20)
	l.tooltip_text = "The spirit lives inside its host, so it knows the host's nature."


func _show_speakers() -> void:
	Ui.frame(speak_row, Rect2(0, -2, size.x, 32), Color(0.08, 0.06, 0.04, 0.92), Color("#5a4428"), 1)
	Ui.label(speak_row, "Speaking:", Vector2(6, 6), 13, Ui.DIM)
	var keys: Array = cast.keys().filter(func(k): return cast[k].get("company", false))
	for i in keys.size():
		var key: String = keys[i]
		var who := _who(key)
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
	var me := _who(host)
	var known := Ui.label(speak_row, "Known traits: " + ", ".join(me.get("traits", [])), Vector2(size.x - 366, 7), 12, Ui.DIM, 362, HORIZONTAL_ALIGNMENT_RIGHT)
	known.tooltip_text = "The spirit lives inside its host, so it knows the host's nature."


func _reply_button(bb: String, indent: float) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.07, 0.04, 0.9)
	normal.border_color = Color("#5a4428")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.22, 0.15, 0.08, 0.97)
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
	var w := size.x - 8.0 - indent
	b.add_child(rt)
	replies.add_child(b)
	var f: Font = Game.main.theme.default_font
	var h := maxf(f.get_multiline_string_size(rt.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, w, 13).y, 18.0)
	b.size = Vector2(size.x, h + 10)
	rt.position = Vector2(indent, 5)
	rt.size = Vector2(w, h + 2)
	return b


func choose(i: int) -> void:
	if choosing == "":
		return
	var id := choosing
	var opts: Array = choice_step.options
	if i < 0 or i >= opts.size():
		return
	choosing = ""
	var o: Dictionary = opts[i]
	_clear_choices()
	var rest: Array = []
	# The chosen reply is marked in the history (▸, and the check with its chance); the quest log
	# also gets whether the check passed.
	var mark := "[color=#%s]▸[/color] " % Ui.DIM.to_html(false)
	if o.has("checks"):
		var p := _check_chance(o.checks)
		mark += "[color=#%s][%s %d%%][/color] " % [_odds_color(p).to_html(false), _check_label(o.checks), p]
	var extra := ""
	if o.has("ok"):
		extra = "  [color=#%s](%s)[/color]" % [Ui.DIM.to_html(false), "passed" if o.ok else "failed"]
		if not o.ok and journal != "":
			effect.emit("fail:" + journal)   # failed checks cut the quest's experience
	if o.has("say"):
		rest.append({"s": o.say, "t": o.t, "mark": mark, "extra": extra})
	elif o.get("silent", false):
		log_line(mark + "[i]%s[/i]" % o.t, extra)
	rest.append_array(o.get("after", []))
	_queued = []
	choice_made.emit(id, i)
	rest.append_array(_queued)
	_queued = []
	steps = steps.slice(0, idx + 1) + rest + steps.slice(idx + 1)
	_next()


## Shows buttons in the reply area, e.g. "Continue" at the end of a scene.
func show_buttons(list: Array) -> void:
	_clear_choices()
	var x := (size.x - list.size() * 150 + 10) / 2.0
	for i in list.size():
		Ui.btn(replies, list[i][0], Rect2(x + i * 150, 20, 140, 32), list[i][1])


# ---------------------------------------------------------------- pause and history

func set_paused(on: bool) -> void:
	paused = on
	timer.paused = on
	if not on and timer.is_stopped() and running and choosing == "":
		timer.start(0.6)
	if not log_panel.visible and running and choosing == "":
		prompt.text = "Paused  ·  P or click to resume" if on else ""


func open_history() -> void:
	if log_panel.visible or history.is_empty():
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


func _at_bottom() -> bool:
	var bar := log_text.get_v_scroll_bar()
	return bar.value >= bar.max_value - bar.page - 2.0


func _on_log_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if (e.button_index == MOUSE_BUTTON_WHEEL_DOWN and _at_bottom()) or e.button_index == MOUSE_BUTTON_LEFT:
			close_history()
			accept_event()


## Clicks on the box itself (the box stops the mouse, so they never reach _unhandled_input).
func _gui_input(e: InputEvent) -> void:
	if _mouse(e):
		accept_event()


## Left click: continue (or resume); mouse wheel up: the history. True if it was used.
func _mouse(e: InputEvent) -> bool:
	if not (e is InputEventMouseButton and e.pressed) or Game.main.modal_open:
		return false
	if e.button_index == MOUSE_BUTTON_WHEEL_UP:
		open_history()
		return true
	if e.button_index == MOUSE_BUTTON_LEFT and not log_panel.visible and running:
		if paused:
			set_paused(false)
		else:
			_next()
		return true
	return false


func _unhandled_input(e: InputEvent) -> void:
	if not is_visible_in_tree() or Game.main.modal_open:
		return
	if e is InputEventMouseButton:
		if e.pressed and _mouse(e):
			get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo:
		if log_panel.visible:
			if e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_H, KEY_ESCAPE]:
				close_history()
			else:
				return
		elif e.keycode == KEY_H:
			open_history()
		elif e.keycode == KEY_P and running:
			set_paused(not paused)
		elif choosing != "" and e.keycode >= KEY_1 and e.keycode <= KEY_9:
			choose(e.keycode - KEY_1)
		elif e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and running:
			if paused:
				set_paused(false)
			else:
				_next()
		else:
			return
		get_viewport().set_input_as_handled()


## For the developer tour: run ahead to the next choice or the end.
func skip_to_choice() -> void:
	while running and choosing == "" and not paused:
		_next()
