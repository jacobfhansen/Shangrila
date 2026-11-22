class_name Ui
extends RefCounted
## Small helpers for building the 640x480 screens in code, the way the original placed
## every picture with SetRect().

const GOLD := Color("#e8c46a")
const TEXT := Color("#f0e2bc")
const DIM := Color("#a89878")
const INK := Color("#3a2410")
const RED := Color("#ff5a40")
const PANEL := Color(0.08, 0.06, 0.04, 0.88)
const EDGE := Color("#8a6a3a")

static var _tex_cache := {}


static func tex(name: String) -> Texture2D:
	if not _tex_cache.has(name):
		_tex_cache[name] = load("res://assets/%s.png" % name)
	return _tex_cache[name]


static func place(c: Control, r: Rect2) -> void:
	c.position = r.position
	c.size = r.size


## Breaks a tooltip into lines of at most `width` characters at spaces (tooltips are drawn as
## one line and would run off the window). Existing line breaks are kept.
static func tip(text: String, width := 64) -> String:
	var out := []
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			if line != "" and line.length() + 1 + word.length() > width:
				out.append(line)
				line = word
			else:
				line = word if line == "" else line + " " + word
		out.append(line)
	return "\n".join(out)


static func btn(parent: Node, text: String, r: Rect2, cb: Callable = Callable(), tip := "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = Ui.tip(tip)
	b.clip_text = true
	if cb.is_valid():
		b.pressed.connect(cb)
	parent.add_child(b)
	place(b, r)
	return b


static func label(parent: Node, text: String, pos: Vector2, fsize := 13, col := TEXT, w := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.position = pos
	if w > 0.0:
		l.size.x = w
		l.horizontal_alignment = align
		l.clip_text = true
	parent.add_child(l)
	return l


static func title(parent: Node, text: String, pos: Vector2, fsize := 26, w := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(parent, text, pos, fsize, GOLD, w, align)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	l.clip_text = false
	return l


static func image(parent: Node, name: String, r: Rect2, tile := false) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(name)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if tile:
		t.stretch_mode = TextureRect.STRETCH_TILE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(t)
	place(t, r)
	return t


static func shade(parent: Node, r: Rect2, col := Color(0, 0, 0, 0.45)) -> ColorRect:
	var c := ColorRect.new()
	c.color = col
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	place(c, r)
	return c


static func frame(parent: Node, r: Rect2, bg := PANEL, edge := EDGE, width := 2) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 3
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	place(p, r)
	return p


## A parchment panel (procedural texture, see tools/make_textures.py).
static func parchment(parent: Node, r: Rect2) -> Control:
	var holder := frame(parent, r, Color("#d8c08a"), Color("#5a3a18"), 3)
	var t := image(holder, "parchment", Rect2(Vector2(3, 3), r.size - Vector2(6, 6)), true)
	t.modulate = Color(1, 0.95, 0.85, 0.55)
	return holder


## The stone background used behind most screens.
static func stone_background(parent: Node, darken := 0.35) -> void:
	image(parent, "dark_stone", Rect2(0, 0, 640, 480), true)
	shade(parent, Rect2(0, 0, 640, 480), Color(0, 0, 0, darken))


static func chain(parent: Node, pos: Vector2, length: float) -> void:
	# The chain strip is 696x36; squeeze it to the requested length at half height.
	var t := image(parent, "chain", Rect2(pos, Vector2(length, 18)))
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # drop the black background
	t.material = m
