extends Control
## BackWin - the "About" picture shown at start-up until the mouse button is pressed.


func _ready() -> void:
	Ui.stone_background(self, 0.55)
	Ui.frame(self, Rect2(170, 70, 300, 242), Color(0, 0, 0, 0.6), Color("#a07a40"), 3)
	Ui.image(self, "Sword", Rect2(180, 80, 280, 222))
	Ui.title(self, "SHANGRILA", Vector2(0, 14), 40, 640, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.label(self, "An adventure game for the Macintosh", Vector2(0, 326), 15, Ui.TEXT, 640, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.label(self, "Written in Pascal by Jacob Flemming Hansen, 1997", Vector2(0, 350), 13, Ui.DIM, 640, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.label(self, "Recreated in Godot, 2026", Vector2(0, 370), 13, Ui.DIM, 640, HORIZONTAL_ALIGNMENT_CENTER)
	var hint := Ui.label(self, "- click to continue -", Vector2(0, 430), 13, Ui.GOLD, 640, HORIZONTAL_ALIGNMENT_CENTER)
	var tw := create_tween().set_loops()
	tw.tween_property(hint, "modulate:a", 0.25, 0.9)
	tw.tween_property(hint, "modulate:a", 1.0, 0.9)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		Game.main.goto("title")


func _unhandled_key_input(e: InputEvent) -> void:
	if e.is_pressed():
		Game.main.goto("title")
