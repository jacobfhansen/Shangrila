extends Control
## Prologue: "Dawn at the shrine". The spirit wakes (eyelids opening on the camp), listens to
## the Harrow Company's morning chatter, chooses whom to hold on to, and makes its first choice
## through that host. The text is in scripts/data/prologue.gd, the dialogue window is DialogueBox.

const P = preload("res://scripts/data/prologue.gd")

var host := ""
var chosen := -1
var painting: ScenePainting
var box: DialogueBox


func _ready() -> void:
	Ui.stone_background(self, 0.6)
	painting = ScenePainting.new()
	add_child(painting)
	Ui.place(painting, Rect2(8, 8, 624, 150))
	Ui.frame(self, Rect2(6, 6, 628, 154), Color(0, 0, 0, 0), Color("#a07a40"), 2)
	box = DialogueBox.new()
	box.cast = P.company_cast()
	Ui.place(box, Rect2(8, 166, 624, 306))
	add_child(box)
	box.effect.connect(_on_effect)
	box.choice_made.connect(_on_choice)
	box.finished.connect(_on_finished)
	var steps: Array = P.INTRO.duplicate()
	steps[steps.size() - 1] = host_choice()
	box.play(steps)


func host_choice() -> Dictionary:
	var opts := []
	for key in P.ORDER:
		var who: Dictionary = P.CAST[key]
		opts.append({"portrait": key, "tip": who.blurb,
			"bb": "[color=#%s]%s[/color], %s %s.  [i]%s[/i]" % [Ui.GOLD.to_html(false), who.name, who.race, who.cls, P.SEEN_AS[key]]})
	return {"choice": "host", "options": opts, "prompt": "Choose whom to hold on to (1-5)"}


func reply_choice() -> Dictionary:
	var opts := []
	for rep in P.HOSTS[host].replies:
		var o: Dictionary = rep.duplicate()
		if not o.get("silent", false):
			o["say"] = host
		opts.append(o)
	return {"choice": "reply", "options": opts, "speakers": true, "prompt": "Choose a reply (1-4)"}


func _on_choice(id: String, i: int) -> void:
	if id == "host":
		host = P.ORDER[i]
		box.host = host
		box.log_line("[center][color=#%s][i]The spirit takes hold of %s.[/i][/color][/center]" % [DialogueBox.SPIRIT.to_html(false), P.CAST[host].name])
		var rest: Array = P.TOUCH.duplicate()
		for t in P.HOSTS[host].inner:
			rest.append({"i": t})
		rest.append(reply_choice())
		box.queue(rest)
	elif id == "reply":
		chosen = i
		box.queue([{"n": "The Harrow Company sets off down the road to Lehan. Inside one of them, something very old is learning to see."}])


func _on_effect(name: String) -> void:
	if name == "eyes":
		_eyes_fx()
	elif name == "touch":
		_touch_fx()


func _on_finished() -> void:
	if get_meta("args", {}).get("new_game", false):
		box.show_buttons([["Continue", _on_continue]])
	else:
		box.show_buttons([["Play it again", func(): Game.main.goto("prologue")], ["Main menu", _on_back]])


func _on_continue() -> void:
	Game.start_company(host, chosen)
	Game.main.goto("world", {"road": true})


## Eyelids opening on the scene: a few heavy flutters, then wide open.
func _eyes_fx() -> void:
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
	box.log_line("[center][color=#%s]* * *[/color][/center]" % DialogueBox.SPIRIT.to_html(false))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE and not box.log_panel.visible:
		_on_back()
		get_viewport().set_input_as_handled()


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
