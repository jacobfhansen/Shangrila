class_name QuestLog
extends Control
## The quest log: a window over whatever screen is open, listing the current, not yet taken and
## finished quests, with every conversation of the chosen quest as it was played (see Journal).
## Opened with a Quests button or J; closed with Close, J or Esc.

var list_box: Control
var text: RichTextLabel
var shown := ""


## Opens the log over the current screen (unless another window is open).
static func open() -> void:
	if Game.main.modal_open:
		return
	var w := QuestLog.new()
	Ui.place(w, Rect2(0, 0, 640, 480))   # sized before _ready builds it
	Game.main.add_child(w)


func _ready() -> void:
	Game.main.modal_open = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	Ui.place(dim, Rect2(0, 0, 640, 480))
	Ui.frame(self, Rect2(14, 14, 612, 452), Color("#1a120a"), Color("#a07a40"), 2)
	Ui.title(self, "Quest Log", Vector2(28, 20), 22)
	Ui.label(self, "Every conversation, as it was played.", Vector2(200, 30), 12, Ui.DIM, 300)
	Ui.btn(self, "Close", Rect2(530, 24, 82, 28), close, "Close the quest log (J / Esc)")

	Ui.frame(self, Rect2(24, 60, 176, 396))
	list_box = Control.new()
	add_child(list_box)
	Ui.place(list_box, Rect2(28, 64, 168, 388))

	Ui.frame(self, Rect2(206, 60, 410, 396))
	var italic: SystemFont = Game.main.theme.default_font.duplicate()
	italic.font_italic = true
	text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = true
	text.selection_enabled = false
	text.add_theme_font_override("italics_font", italic)
	text.add_theme_color_override("default_color", Ui.TEXT)
	text.add_theme_font_size_override("normal_font_size", 13)
	text.add_theme_font_size_override("italics_font_size", 13)
	text.add_theme_font_size_override("bold_font_size", 14)
	text.add_theme_constant_override("paragraph_separation", 5)
	Ui.place(text, Rect2(216, 68, 392, 380))   # sized before it enters the tree
	add_child(text)

	var quests := Journal.listed()
	if quests.is_empty():
		text.text = "[color=#a89878]No quests yet. People in town may have work for you.[/color]"
		return
	_build_list(quests)
	_show(quests[0].key)


func _build_list(quests: Array) -> void:
	var y := 0.0
	for q in quests:
		var st := Journal.status(q.key)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s\n%s" % [q.name, Journal.STATUS_NAMES[st]]
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", Ui.DIM if st == "done" else Ui.TEXT)
		b.pressed.connect(_show.bind(q.key))
		b.set_meta("quest", q.key)
		Ui.place(b, Rect2(0, y, 168, 44))
		list_box.add_child(b)
		y += 48


func _show(key: String) -> void:
	shown = key
	for b in list_box.get_children():
		b.button_pressed = b.get_meta("quest") == key
	var name: String = ""
	for q in Journal.QUESTS:
		if q.key == key:
			name = q.name
	var st := Journal.status(key)
	var out: Array = ["[b][color=#e8c46a]%s[/color][/b]  [color=#a89878](%s)[/color]" % [name.to_upper(), Journal.STATUS_NAMES.get(st, "Not known yet")]]
	var scenes := Journal.scenes(key)
	if scenes.is_empty():
		out.append("")
		out.append("[color=#a89878][i]This quest began before the quest log was kept, so nothing of it was written down.[/i][/color]")
	for sc in scenes:
		out.append("")
		out.append("[center][color=#e8c46a]— %s —[/color][/center]" % sc.place)
		out.append_array(sc.lines)
	text.text = "\n".join(out)
	# Current quests open at the latest scene (where you left off); finished ones at the start.
	if st == "done":
		text.scroll_to_line(0)
	else:
		text.scroll_to_line.call_deferred(maxi(0, text.get_line_count() - 1))


func close() -> void:
	Game.main.modal_open = false
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_J, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		close()
