extends Control
## Screen manager - the equivalent of OpenAWindow / InitAWindow and the modal picture
## dialogs (MyRealyQuit, RealyTrash, ViewItem, GetTheName).

signal _modal_done(result: Variant)

var current: Control
var current_name := ""
var modal_open := false


func _ready() -> void:
	Game.main = self
	theme = _make_theme()
	clip_contents = true
	goto("about")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tour="):
			add_child(load("res://scripts/dev_tour.gd").new())


func goto(screen: String, args := {}) -> void:
	if current:
		current.queue_free()
	var s: Control = load("res://scripts/screens/%s.gd" % screen).new()
	s.set_meta("args", args)
	s.size = Vector2(640, 480)
	current = s
	current_name = screen
	add_child(s)


# ---------------------------------------------------------------- theme

func _make_theme() -> Theme:
	var t := Theme.new()
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "URW Palladio L", "P052", "TeX Gyre Pagella", "Georgia", "DejaVu Serif", "serif"])
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	t.default_font = f
	t.default_font_size = 13

	var mk := func(bg: Color, edge: Color) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = edge
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		return sb
	t.set_stylebox("normal", "Button", mk.call(Color("#3a2814"), Color("#a07a40")))
	t.set_stylebox("hover", "Button", mk.call(Color("#54391c"), Color("#e0b060")))
	t.set_stylebox("pressed", "Button", mk.call(Color("#e0c080"), Color("#fff0c0")))
	t.set_stylebox("disabled", "Button", mk.call(Color(0.15, 0.13, 0.11, 0.8), Color("#4a4030")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Ui.TEXT)
	t.set_color("font_hover_color", "Button", Color("#fff4d0"))
	t.set_color("font_pressed_color", "Button", Ui.INK)
	t.set_color("font_disabled_color", "Button", Color("#6a6050"))
	t.set_font_size("font_size", "Button", 13)

	t.set_stylebox("normal", "LineEdit", mk.call(Color("#f0e0b8"), Color("#5a3a18")))
	t.set_stylebox("focus", "LineEdit", mk.call(Color("#fff0c8"), Color("#a07a40")))
	t.set_color("font_color", "LineEdit", Ui.INK)
	t.set_color("caret_color", "LineEdit", Ui.INK)
	t.set_font_size("font_size", "LineEdit", 16)

	var tip := mk.call(Color("#1a120a"), Color("#a07a40"))
	tip.set_border_width_all(1)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", Ui.TEXT)
	t.set_font_size("font_size", "TooltipLabel", 12)
	return t


# ---------------------------------------------------------------- modal dialogs

func _overlay() -> Control:
	modal_open = true
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.45)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.position = Vector2.ZERO
	ov.size = Vector2(640, 480)
	add_child(ov)
	return ov


func _close(ov: Control) -> void:
	ov.queue_free()
	modal_open = false


func _box(ov: Control, w: float, h: float) -> Control:
	return Ui.parchment(ov, Rect2((640 - w) / 2.0, (480 - h) / 2.0, w, h))


func _ink_label(p: Node, text: String, r: Rect2, fsize := 15) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Ui.INK)
	l.add_theme_font_size_override("font_size", fsize)
	Ui.place(l, r)   # size it before it enters the tree, so autowrap never sees width 0
	p.add_child(l)
	return l


## "Do you really want to ...?"  Returns true for OK.
func confirm(text: String, ok_text := "OK") -> bool:
	var ov := _overlay()
	var b := _box(ov, 260, 140)
	_ink_label(b, text, Rect2(14, 12, 232, 70))
	Ui.btn(b, "Cancel", Rect2(20, 96, 90, 28), func(): _modal_done.emit(false))
	Ui.btn(b, ok_text, Rect2(150, 96, 90, 28), func(): _modal_done.emit(true))
	var r: bool = await _modal_done
	_close(ov)
	return r


func message(text: String) -> void:
	var ov := _overlay()
	var w := 280.0 if text.length() < 120 else 340.0
	var f: Font = theme.default_font
	var th := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, w - 28, 15).y
	var th_box := maxf(74.0, th + 8)
	var b := _box(ov, w, th_box + 66)
	_ink_label(b, text, Rect2(14, 12, w - 28, th_box))
	Ui.btn(b, "OK", Rect2((w - 90) / 2, th_box + 24, 90, 28), func(): _modal_done.emit(true))
	await _modal_done
	_close(ov)


## GetTheName - the name dialog shown after Accept.
func ask_name() -> String:
	var ov := _overlay()
	var b := _box(ov, 260, 150)
	_ink_label(b, "What is the name of this character?", Rect2(14, 10, 232, 40))
	var le := LineEdit.new()
	le.max_length = 12
	le.placeholder_text = "Name"
	b.add_child(le)
	Ui.place(le, Rect2(30, 58, 200, 32))
	var ok := Ui.btn(b, "OK", Rect2(85, 106, 90, 28), func(): _modal_done.emit(le.text.strip_edges()))
	ok.disabled = true
	le.text_changed.connect(func(t: String): ok.disabled = t.strip_edges() == "")
	le.text_submitted.connect(func(t: String):
		if t.strip_edges() != "":
			_modal_done.emit(t.strip_edges()))
	le.grab_focus.call_deferred()
	var r: String = await _modal_done
	_close(ov)
	return r


## ViewItem - the item info card.
func show_item(id: int) -> void:
	var it := Game.item(id)
	var ov := _overlay()
	var b := _box(ov, 300, 260)
	var ic := ItemIcon.new()
	ic.item_id = id
	b.add_child(ic)
	Ui.place(ic, Rect2(14, 14, 40, 40))
	var name_l := _ink_label(b, it.name, Rect2(62, 16, 220, 34), 21)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var d := _ink_label(b, it.desc, Rect2(20, 62, 260, 54), 14)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var dmg: String = "-" if it.dmg[1] == 0 else "%d-%d" % [it.dmg[0], it.dmg[1]]
	var lines := [["Weight", it.weight], ["Defense", it.defense], ["Attack", it.attack], ["Damage", dmg]]
	for i in lines.size():
		var l := _ink_label(b, "%s:" % lines[i][0], Rect2(24, 124 + i * 18, 80, 18), 13)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var v := _ink_label(b, str(lines[i][1]), Rect2(100, 124 + i * 18, 60, 18), 13)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var price := _ink_label(b, "Value: " + Game.money_string(it.price), Rect2(24, 198, 200, 18), 13)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	Ui.btn(b, "OK", Rect2(200, 218, 80, 28), func(): _modal_done.emit(true))
	await _modal_done
	_close(ov)


## A list of choices (used for Use / Equip in combat). Returns the index, or -1 for Cancel.
func choose(text: String, options: Array) -> int:
	var ov := _overlay()
	var n := options.size()
	var b := _box(ov, 260, 100 + n * 32)
	_ink_label(b, text, Rect2(14, 8, 232, 40))
	for i in n:
		Ui.btn(b, options[i], Rect2(30, 52 + i * 32, 200, 28), func(): _modal_done.emit(i))
	Ui.btn(b, "Cancel", Rect2(85, 58 + n * 32, 90, 28), func(): _modal_done.emit(-1))
	var r: int = await _modal_done
	_close(ov)
	return r


## Default action per character, used by the Defaults button and by auto-combat.
func tactics() -> void:
	var ov := _overlay()
	var n := Game.party.size()
	var b := _box(ov, 360, 108 + n * 40)
	_plain(b, "Default actions", Rect2(0, 8, 360, 22), 17, HORIZONTAL_ALIGNMENT_CENTER)
	_plain(b, "Used by the Defaults button and by auto-combat", Rect2(0, 30, 360, 18), 12, HORIZONTAL_ALIGNMENT_CENTER)
	for i in n:
		var c: Dictionary = Game.party[i]
		var y := 56 + i * 40
		var p := Portrait.new()
		b.add_child(p)
		Ui.place(p, Rect2(20, y, 34, 34))
		p.index = c.icon
		_plain(b, c.name, Rect2(62, y, 120, 18), 14)
		_plain(b, Game.CLASSES[c.cls], Rect2(62, y + 17, 120, 16), 11)
		var opts: Array = Game.tactics_for(c)
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		for k in opts:
			var label: String = Game.TACTICS[k]
			if k == "spell":
				label = Game.spell_for(c).name
			ob.add_item(label)
		ob.selected = opts.find(Game.tactic(c))
		ob.item_selected.connect(func(idx: int): c.tactic = opts[idx])
		b.add_child(ob)
		Ui.place(ob, Rect2(190, y + 3, 150, 28))
	Ui.btn(b, "OK", Rect2(135, 64 + n * 40, 90, 28), func(): _modal_done.emit(true))
	await _modal_done
	_close(ov)


## A single-line ink label (no autowrap, so it never grows out of its rect).
func _plain(p: Node, text: String, r: Rect2, fsize := 13, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.clip_text = true
	l.add_theme_color_override("font_color", Ui.INK)
	l.add_theme_font_size_override("font_size", fsize)
	p.add_child(l)
	Ui.place(l, r)
	return l
