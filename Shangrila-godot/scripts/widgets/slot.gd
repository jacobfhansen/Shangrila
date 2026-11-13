class_name Slot
extends Panel
## A box that can hold an item, be dragged from, and be dropped on.
## Replaces the hand-written drag loops (DragAndDropViewCha / DragAndDropShop).

signal clicked(slot: Slot)

var slot_id := 0
var kind := ""
var handler: Object = null     # must implement can_drop(slot, data) and drop(slot, data)
var draggable := false
var icon: ItemIcon
var _style: StyleBoxFlat

var item_id := 0:
	set(v):
		item_id = v
		if icon:
			icon.item_id = v
		_update_tip()
		queue_redraw()

var hint := "":
	set(v):
		hint = v
		_update_tip()

## Faint text shown while the slot is empty (e.g. "Head").
var caption := "":
	set(v):
		caption = v
		queue_redraw()


func _draw() -> void:
	if item_id == 0 and caption != "":
		var f := get_theme_default_font()
		var fs := 9
		for line_i in caption.split("\n").size():
			var line: String = caption.split("\n")[line_i]
			var w := f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var n := caption.split("\n").size()
			var y := size.y / 2.0 + 3 - (n - 1) * 5 + line_i * 10
			draw_string(f, Vector2((size.x - w) / 2.0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.8, 0.7, 0.5, 0.55))


static func make(parent: Node, r: Rect2, id: int, k: String, h: Object) -> Slot:
	var s := Slot.new()
	s.slot_id = id
	s.kind = k
	s.handler = h
	Ui.place(s, r)
	parent.add_child(s)
	return s


func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.05, 0.04, 0.03, 0.75)
	_style.border_color = Color("#6a5030")
	_style.set_border_width_all(1)
	_style.set_corner_radius_all(2)
	add_theme_stylebox_override("panel", _style)
	mouse_filter = Control.MOUSE_FILTER_STOP
	icon = ItemIcon.new()
	add_child(icon)
	icon.position = Vector2(2, 2)
	icon.size = size - Vector2(4, 4)
	icon.item_id = item_id


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and icon:
		icon.size = size - Vector2(4, 4)


func set_border(col: Color, w := 1) -> void:
	_style.border_color = col
	_style.set_border_width_all(w)


func _update_tip() -> void:
	if item_id != 0:
		var it := Game.item(item_id)
		var t: String = it.name
		if it.defense: t += "\nDefense %d" % it.defense
		t += "\nWeight %d" % it.weight
		tooltip_text = t + ("\n" + hint if hint != "" else "")
	else:
		tooltip_text = hint


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


func _get_drag_data(_at: Vector2) -> Variant:
	if not draggable or item_id == 0:
		return null
	var holder := Control.new()
	var p := ItemIcon.new()
	p.item_id = item_id
	p.size = Vector2(32, 32)
	p.position = Vector2(-16, -16)
	holder.add_child(p)
	set_drag_preview(holder)
	return {"type": "item", "item": item_id, "src": slot_id, "from": kind}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return handler != null and data is Dictionary and data.get("type") == "item" and handler.can_drop(self, data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	handler.drop(self, data)
