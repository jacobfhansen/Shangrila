extends Control
## MainDlog - New / Resume / Quit.


func _ready() -> void:
	Ui.stone_background(self, 0.4)
	Ui.title(self, "SHANGRILA", Vector2(0, 40), 46, 640, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.chain(self, Vector2(120, 108), 400)
	# The two painted portraits flank the menu.
	for i in 2:
		var x := 40 if i == 0 else 460
		Ui.frame(self, Rect2(x - 4, 156, 148, 121), Color(0, 0, 0, 0.6), Color("#a07a40"), 2)
		Ui.image(self, "The_Man" if i == 0 else "The_Enemy", Rect2(x, 160, 140, 113))
	Ui.btn(self, "New", Rect2(260, 172, 120, 34), _on_new)
	var res := Ui.btn(self, "Resume", Rect2(260, 224, 120, 34), _on_resume)
	res.disabled = not Game.has_save()
	if res.disabled:
		res.tooltip_text = "No saved game yet"
	Ui.btn(self, "Quit", Rect2(260, 276, 120, 34), func(): get_tree().quit())
	Ui.label(self, "Something old stirs beneath a roadside shrine.\nFive travellers have made camp beside it for the night.",
		Vector2(0, 360), 13, Ui.DIM, 640, HORIZONTAL_ALIGNMENT_CENTER)


func _on_new() -> void:
	if Game.has_save() and not await Game.main.confirm("Start a new game?\nYour saved game stays on disk until you save again."):
		return
	Game.main.goto("prologue", {"new_game": true})


func _on_resume() -> void:
	var screen := Game.load_game()
	if screen == "":
		await Game.main.message("The saved game could not be read.")
		return
	Game.main.goto(screen)
