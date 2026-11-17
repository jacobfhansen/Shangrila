class_name BattleWindow
extends Control
## A fight away from the mines, shown in a window (used on the road). Everyone acts on their
## own, by their tactics and traits. Before each round the spirit may help its host: guide
## their blow (Combat.blessed) or turn aside the next blow aimed at them (Combat.warded).
## Emits `done(result, used)` with result "won" / "lost" and used = {"bless": n, "ward": n}.

signal done(result: String, used: Dictionary)

var combat: Combat
var title := "Ambush!"
var host_index := 0
var used := {"bless": 0, "ward": 0}
var box: DialogueBox      # optional: the combat log also goes into its history

var enemy_panel: EnemyPanel
var ports: Array = []
var bars: Array = []
var order_labels: Array = []
var log_view: LogView
var log_lines: Array = []
var spirit_btns: Array = []
var _spirit_choice := ""
signal _spirit_chosen


func start(fixed: Array) -> void:
	combat = Combat.new(0, fixed)
	_build()
	_say("%s You face %s." % [title, combat.describe()])
	_run()


func _build() -> void:
	var w := size.x
	Ui.frame(self, Rect2(0, 0, w, size.y), Color(0.07, 0.05, 0.03, 0.97), Color("#a07a40"), 2)
	Ui.label(self, title, Vector2(12, 6), 17, Ui.GOLD)

	enemy_panel = EnemyPanel.new()
	enemy_panel.combat = combat
	add_child(enemy_panel)
	Ui.place(enemy_panel, Rect2(8, 32, 290, 236))

	var px := 306.0
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		var y := 32.0 + i * 47
		var p := Portrait.new()
		add_child(p)
		Ui.place(p, Rect2(px, y, 40, 40))
		p.index = c.icon
		ports.append(p)
		var nm: String = c.name + ("  (host)" if i == host_index else "")
		Ui.label(self, nm, Vector2(px + 46, y - 2), 12, Ui.GOLD if i == host_index else Ui.TEXT, 150)
		var b := StatusBars.new()
		add_child(b)
		Ui.place(b, Rect2(px + 46, y + 14, 54, 26))
		bars.append(b)
		var ol := Ui.label(self, "", Vector2(px + 106, y + 14), 11, Ui.DIM, w - px - 112)
		order_labels.append(ol)

	Ui.frame(self, Rect2(8, 274, w - 16, 54), Color(0, 0, 0, 0.35), Color("#5a4428"), 1)
	log_view = LogView.new()
	Ui.place(log_view, Rect2(14, 276, w - 24, 50))   # sized before _ready builds it
	add_child(log_view)
	log_view.tooltip_text = "Mouse wheel: scroll back through the fight"

	var host_name: String = Game.party[host_index].name
	Ui.label(self, "The spirit:", Vector2(12, size.y - 30), 13, DialogueBox.SPIRIT)
	var defs := [["Guide the blow", "bless", "1: Lend %s's next blow a little of your sureness." % host_name],
		["Ward", "ward", "2: Turn aside the next blow aimed at %s." % host_name],
		["Do nothing", "none", "3: Let them fight on their own."]]
	for k in defs.size():
		var btn := Ui.btn(self, defs[k][0], Rect2(96 + k * 136, size.y - 36, 128, 28),
			_on_spirit.bind(defs[k][1]), defs[k][2])
		spirit_btns.append(btn)
	_refresh()


func _say(t: String) -> void:
	log_lines.append(t)
	log_view.add_line(t)
	if box:
		box.log_line("[color=#%s]%s[/color]" % [Ui.DIM.to_html(false), t])


## The order a character gives themselves, by their tactic and their nature.
func _own_order(i: int) -> Dictionary:
	var c: Dictionary = Game.party[i]
	var traits: Array = c.get("traits", [])
	var av := combat.available(i)
	if "Cowardly" in traits and av.hide and not combat.hidden.has(i):
		return {"act": "hide"}
	if "Cautious" in traits and Game.my_random(1, 100) <= 40:
		return {"act": "parry"}
	return combat.default_order(i)


func _refresh(orders := {}) -> void:
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		bars[i].who = c
		ports[i].modulate = Color(0.45, 0.3, 0.3) if c.hits <= 0 else Color.WHITE
		var t := ""
		if c.hits <= 0:
			t = "Down"
		elif orders.has(i):
			t = Combat.order_text(orders[i], combat).replace("\n", ": ")
		if combat.hidden.has(i):
			t = "Hidden" + ((", " + t) if t != "" else "")
		order_labels[i].text = t


func _on_spirit(kind: String) -> void:
	_spirit_choice = kind
	_spirit_chosen.emit()


func _unhandled_key_input(e: InputEvent) -> void:
	if not is_visible_in_tree() or spirit_btns.is_empty() or spirit_btns[0].disabled:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		var map := {KEY_1: "bless", KEY_2: "ward", KEY_3: "none"}
		if map.has(e.keycode):
			_on_spirit(map[e.keycode])
			get_viewport().set_input_as_handled()


func _run() -> void:
	while combat.outcome() == "":
		var orders := {}
		for i in Game.party.size():
			if Game.party[i].hits > 0:
				orders[i] = _own_order(i)
		_refresh(orders)
		var host_up: bool = Game.party[host_index].hits > 0
		for b in spirit_btns:
			b.disabled = false
		spirit_btns[0].disabled = not host_up or orders.get(host_index, {}).get("act", "") != "attack"
		spirit_btns[1].disabled = not host_up
		await _spirit_chosen
		for b in spirit_btns:
			b.disabled = true
		match _spirit_choice:
			"bless":
				combat.blessed[host_index] = true
				used.bless += 1
				_say("The spirit steadies %s's hand." % Game.party[host_index].name)
			"ward":
				combat.warded[host_index] = true
				used.ward += 1
				_say("The spirit wraps itself around %s." % Game.party[host_index].name)
		for a in combat.begin_round(orders):
			if not is_inside_tree() or combat.outcome() != "":
				break
			var lines := combat.act(a, orders)
			if lines.is_empty():
				continue
			if a.side == "p":
				ports[a.i].highlight = true
				var o: Dictionary = orders[a.i]
				if o.has("target") and not o.has("ally"):
					enemy_panel.hit(o.target)
			for l in lines:
				_say(l)
			_refresh(orders)
			await get_tree().create_timer(0.7).timeout
			if a.side == "p":
				ports[a.i].highlight = false
		if not is_inside_tree():
			return
		combat.end_round()
	var result := combat.outcome()
	if result == "won":
		for l in combat.rewards():
			_say(l)
	else:
		for c in Game.party:
			c.hits = maxi(c.hits, 1)
			Game.add_silver(c, -c.silver / 2)
		_say("The company falls.")
	_refresh()
	await get_tree().create_timer(1.6).timeout
	done.emit(result, used)
