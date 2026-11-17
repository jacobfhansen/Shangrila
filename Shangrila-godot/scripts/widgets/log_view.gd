class_name LogView
extends Control
## A scrolling message log (the combat log in the mines and in battle windows). New lines
## appear at the bottom; the mouse wheel scrolls back through earlier ones. While scrolled up
## the view stays put, and a small marker says that newer lines are waiting below.

signal clicked

const MAX_LINES := 300

var font_size := 12
var color := Ui.TEXT
var rtl: RichTextLabel
var more: Label
var _count := 0


func _ready() -> void:
	clip_contents = true
	rtl = RichTextLabel.new()
	rtl.bbcode_enabled = false
	rtl.scroll_active = true
	rtl.scroll_following = true
	rtl.selection_enabled = false
	rtl.focus_mode = Control.FOCUS_NONE
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_color_override("default_color", color)
	rtl.add_theme_constant_override("line_separation", 1)
	add_child(rtl)
	Ui.place(rtl, Rect2(Vector2.ZERO, size))
	rtl.gui_input.connect(_on_input)
	_style_bar(rtl.get_v_scroll_bar())
	more = Ui.label(self, "▼ newer", Vector2(size.x - 70, size.y - 15), 10, Ui.GOLD, 56, HORIZONTAL_ALIGNMENT_RIGHT)
	more.visible = false


func _style_bar(bar: VScrollBar) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.35)
	track.set_corner_radius_all(2)
	track.content_margin_left = 3
	track.content_margin_right = 3
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color("#8a6a3a")
	grab.set_corner_radius_all(2)
	var grab_hi := grab.duplicate()
	grab_hi.bg_color = Ui.GOLD
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("grabber", grab)
	bar.add_theme_stylebox_override("grabber_highlight", grab_hi)
	bar.add_theme_stylebox_override("grabber_pressed", grab_hi)


func add_line(t: String) -> void:
	if _count > 0:
		rtl.newline()
	rtl.add_text(t)
	_count += 1
	while _count > MAX_LINES:
		rtl.remove_paragraph(0)
		_count -= 1


func clear() -> void:
	rtl.clear()
	_count = 0


func _process(_delta: float) -> void:
	var bar := rtl.get_v_scroll_bar()
	more.visible = bar.visible and bar.value < bar.max_value - bar.page - 2.0


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
