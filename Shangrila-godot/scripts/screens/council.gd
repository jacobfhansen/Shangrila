extends Control
## The council house of Lehan: three councillors behind a table, and the talk about the mines
## job (the words and the haggling are in CouncilData).

var box: DialogueBox
var current: Dictionary = {}   # the haggling choice now on screen


func _ready() -> void:
	Ui.stone_background(self, 0.5)
	Ui.title(self, "The Council House", Vector2(0, 8), 24, 640, HORIZONTAL_ALIGNMENT_CENTER)
	# The hall: panelled wall, three councillors, the table in front of them.
	var hall := Rect2(20, 40, 600, 142)
	Ui.frame(self, hall.grow(3), Color("#2a1c0e"), Color("#a07a40"), 2)
	var wall := ColorRect.new()
	wall.color = Color("#3a2a1a")
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	Ui.place(wall, hall)
	for i in 6:
		var panel := ColorRect.new()
		panel.color = Color("#46321e")
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)
		Ui.place(panel, Rect2(hall.position.x + 12 + i * 98, hall.position.y + 8, 88, 82))
	for i in CouncilData.SEATS.size():
		var seat: Array = CouncilData.SEATS[i]
		var who: Dictionary = CouncilData.CAST[seat[0]]
		var fig := TextureRect.new()
		fig.texture = FigureArt.texture_for(self, who.race, who.look)
		fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fig.tooltip_text = "%s, %s" % [seat[1], seat[2]]
		add_child(fig)
		Ui.place(fig, Rect2(118 + i * 170, 46, 64, 128))
	var table := ColorRect.new()
	table.color = Color("#5a3a1e")
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(table)
	Ui.place(table, Rect2(hall.position.x, 134, hall.size.x, hall.end.y - 134))
	var edge := ColorRect.new()
	edge.color = Color("#7a5230")
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)
	Ui.place(edge, Rect2(hall.position.x, 134, hall.size.x, 5))
	for i in CouncilData.SEATS.size():
		var seat: Array = CouncilData.SEATS[i]
		Ui.label(self, seat[1], Vector2(60 + i * 170, 142), 13, Ui.GOLD, 180, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.label(self, seat[2], Vector2(60 + i * 170, 160), 11, Ui.DIM, 180, HORIZONTAL_ALIGNMENT_CENTER)

	Ui.frame(self, Rect2(10, 190, 620, 282), Color("#1a120a"), Color("#a07a40"), 2)
	box = DialogueBox.new()
	box.cast = CouncilData.cast()
	box.host = Game.story.get("host", "")
	Ui.place(box, Rect2(20, 194, 600, 274))   # sized before _ready builds it
	add_child(box)
	box.choice_made.connect(_on_choice)
	_run.call_deferred()


func _run() -> void:
	var steps := CouncilData.visit()
	if box.host == "":
		steps = steps.filter(func(st): return not st.has("i"))
	_remember_choice(steps)
	box.play(steps)
	await box.finished
	box.show_buttons([["Leave", _on_leave]])


func _remember_choice(steps: Array) -> void:
	for st in steps:
		if st.has("choice"):
			current = st


func _on_choice(id: String, i: int) -> void:
	if id != "haggle":
		return
	var o: Dictionary = current.options[i]
	var rest := CouncilData.resolve(o)
	if box.host == "":
		rest = rest.filter(func(st): return not st.has("i"))
	_remember_choice(rest)
	box.queue(rest)


func _on_leave() -> void:
	Game.main.goto("streets", {"at": "council"})
