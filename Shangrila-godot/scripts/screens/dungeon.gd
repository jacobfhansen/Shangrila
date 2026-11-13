extends Control
## DungeonWin - exploring the mines, and fighting in them.
## Keys: W/Up forward, S/Down back, A/Left turn left, D/Right turn right,
## Q/E step sideways, M map.
## In combat: A Attack, P Parry, S Spell, U Use, E Equip, T Turn, F Flee, H Hide, X Pass,
## D Defaults, Esc back/cancel, Space hurry up.

const ENCOUNTER_CHANCE := 12      # percent per step
const QUIET_STEPS := 3            # steps after a fight before the next one can start
const ACTS := ["attack", "parry", "spells", "use", "equip", "turn", "flee", "hide", "pass"]
const ACT_LABELS := ["Attack", "Parry", "Spells", "Use", "Equip", "Turn", "Flee", "Hide", "Pass"]
const ACT_KEYS := {KEY_A: "attack", KEY_P: "parry", KEY_S: "spells", KEY_U: "use", KEY_E: "equip",
	KEY_T: "turn", KEY_F: "flee", KEY_H: "hide", KEY_X: "pass"}
const ACT_TIPS := {
	"attack": "Attack a group with the weapon in hand (A)", "parry": "Defend: harder to hit this round (P)",
	"spells": "Cast this character's spell (S)", "use": "Eat or drink something from the pack (U)",
	"equip": "Ready a weapon from the pack (E)", "turn": "Turn undead - clerics and paladins (T)",
	"flee": "Try to get the party away (F)", "hide": "Slip into the shadows; next attack hits twice as hard (H)",
	"pass": "Do nothing (X)",
}

var view: DungeonView
var view_rect: TextureRect
var automap: Automap
var compass: Compass
var log_lines: Array[String] = []
var log_label: Label
var map_mode := false
var masked_in_map := []
var map_btn: Button

# party display
var ports: Array = []
var bars: Array = []
var order_labels: Array = []

# combat
var combat: Combat = null
var enemy_panel: EnemyPanel
var act_buttons := {}
var status_label: Label
var defaults_btn: Button
var tactics_btn: Button
var auto_btn: Button
var orders := {}
var cur := -1          # party index being given orders
var pending := ""      # action waiting for a target
var phase := ""        # "", "command", "target", "resolve"
var auto := false
var fast := false      # hurry the current round
var steps_quiet := 0
var last_pos := Game.pos


func _ready() -> void:
	Ui.stone_background(self)

	view = DungeonView.new()
	add_child(view)
	view.moved.connect(_after_move)
	Ui.frame(self, Rect2(14, 14, 272, 272), Color.BLACK, Color("#a07a40"), 4)
	view_rect = TextureRect.new()
	view_rect.texture = view.get_texture()
	view_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view_rect.stretch_mode = TextureRect.STRETCH_SCALE
	view_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	view_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view_rect)
	Ui.place(view_rect, Rect2(20, 20, 260, 260))
	automap = Automap.new()
	automap.visible = false
	add_child(automap)
	Ui.place(automap, Rect2(20, 20, 260, 260))
	enemy_panel = EnemyPanel.new()
	enemy_panel.visible = false
	enemy_panel.picked.connect(_on_group_picked)
	add_child(enemy_panel)
	Ui.place(enemy_panel, Rect2(20, 20, 260, 260))

	# Party (DungeonWin 27-32, 50-55).
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		var x := 300 + (i % 2) * 168
		var y := 18 + (i / 2) * 84
		Ui.label(self, c.name, Vector2(x, y), 13, Ui.TEXT, 150)
		var p := Portrait.new()
		add_child(p)
		Ui.place(p, Rect2(x, y + 20, 48, 48))
		p.index = c.icon
		p.tooltip_text = "%s, %s %s" % [c.name, Game.RACES[c.race], Game.CLASSES[c.cls]]
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(_on_portrait_input.bind(i))
		ports.append(p)
		var sb := StatusBars.new()
		add_child(sb)
		Ui.place(sb, Rect2(x + 56, y + 20, 64, 48))
		sb.who = c
		bars.append(sb)
		var ol := Ui.label(self, "", Vector2(x + 122, y + 22), 10, Ui.GOLD, 44)
		ol.clip_text = false
		ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		order_labels.append(ol)

	# Encounters / messages (DungeonWin 9).
	Ui.frame(self, Rect2(10, 292, 266, 128))
	log_label = Ui.label(self, "", Vector2(18, 296), 11, Ui.TEXT, 252)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.clip_text = false
	log_label.size.y = 120
	log_label.max_lines_visible = 8
	log_label.mouse_filter = Control.MOUSE_FILTER_STOP
	log_label.tooltip_text = "Click to hurry the round along"
	log_label.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			fast = true)

	compass = Compass.new()
	add_child(compass)
	Ui.place(compass, Rect2(289, 276, 101, 101))

	# Movement arrows (DungeonWin 20-25).
	var mv := [["↶", 286, 386, _turn.bind(-1), "Turn left (A / Left)"],
		["↑", 323, 386, _walk.bind(0), "Forward (W / Up)"],
		["↷", 360, 386, _turn.bind(1), "Turn right (D / Right)"],
		["←", 286, 423, _walk.bind(3), "Step left (Q)"],
		["↓", 323, 423, _walk.bind(2), "Back (S / Down)"],
		["→", 360, 423, _walk.bind(1), "Step right (E)"]]
	for m in mv:
		var b := Ui.btn(self, m[0], Rect2(m[1], m[2], 34, 33), m[3], m[4])
		b.add_theme_font_size_override("font_size", 18)
		masked_in_map.append(b)

	# Actions box with the nine combat buttons (DungeonWin 10-18).
	Ui.frame(self, Rect2(416, 290, 216, 62))
	Ui.label(self, "Actions", Vector2(424, 293), 14, Ui.GOLD)
	defaults_btn = _small_btn("Defaults", Rect2(482, 294, 52, 20), _on_defaults,
		"Give everyone who has no order yet their default action, then fight the round (D)")
	tactics_btn = _small_btn("Tactics", Rect2(537, 294, 48, 20), _on_tactics, "Set each character's default action")
	auto_btn = _small_btn("Auto", Rect2(588, 294, 40, 20), _on_auto,
		"Auto-combat: every round uses the default actions and plays out fast")
	auto_btn.toggle_mode = true
	status_label = Ui.label(self, "No enemies in sight.", Vector2(424, 316), 11, Ui.DIM, 204)
	status_label.clip_text = false
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in ACTS.size():
		var b := Ui.btn(self, ACT_LABELS[i], Rect2(419 + (i % 3) * 72, 358 + (i / 3) * 39, 67, 34),
			_on_action.bind(ACTS[i]), ACT_TIPS[ACTS[i]])
		act_buttons[ACTS[i]] = b

	# Bottom-left buttons (DungeonWin 1-8, 39).
	var bl := [["Close", 10, 50, _on_close, "Leave the mines"],
		["Save", 64, 46, _on_save, "Save the game"],
		["Examine", 114, 62, _on_examine, "Examine the surroundings"],
		["Sleep", 180, 50, _on_sleep, "Rest: turns endurance into hit points and restores mana"]]
	for e in bl:
		var b := Ui.btn(self, e[0], Rect2(e[1], 430, e[2], 32), e[3], e[4])
		b.add_theme_font_size_override("font_size", 12)
		masked_in_map.append(b)
	map_btn = Ui.btn(self, "Map", Rect2(234, 430, 42, 32), _on_map, "Toggle the map (M)")
	map_btn.add_theme_font_size_override("font_size", 12)
	map_btn.toggle_mode = true

	_explore_ui()
	say("You enter the mines. Daylight fades behind you.")
	_after_move()


func _small_btn(text: String, r: Rect2, cb: Callable, tip: String) -> Button:
	var b := Ui.btn(self, text, r, cb, tip)
	b.add_theme_font_size_override("font_size", 11)
	return b


func say(t: String) -> void:
	log_lines.append(t)
	while log_lines.size() > 12:
		log_lines.pop_front()
	log_label.text = "\n".join(log_lines)
	log_label.lines_skipped = maxi(0, log_label.get_line_count() - log_label.max_lines_visible)


func _refresh_party() -> void:
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		bars[i].who = c
		ports[i].modulate = Color(0.45, 0.3, 0.3) if c.hits <= 0 else Color.WHITE
		var t := ""
		if combat:
			if c.hits <= 0:
				t = "Down"
			elif orders.has(i):
				t = Combat.order_text(orders[i], combat)
			if combat.hidden.has(i):
				t = ("Hidden\n" + t).strip_edges()
		order_labels[i].text = t


# ---------------------------------------------------------------- exploring

func _after_move() -> void:
	compass.queue_redraw()
	if Game.pos != last_pos:
		last_pos = Game.pos
		steps_quiet += 1
		if Game.pos != Game.MINES_START and steps_quiet > QUIET_STEPS and Game.my_random(1, 100) <= ENCOUNTER_CHANCE:
			start_combat(Combat.new(Game.depth()))
			return
	if Game.pos == Game.MINES_START and Game.facing == 2:
		say("Daylight. The way out lies behind you (Close).")


func _turn(d: int) -> void:
	if map_mode or combat or Game.main.modal_open:
		return
	view.turn(d)


## rel: 0 forward, 1 right, 2 back, 3 left - relative to facing.
func _walk(rel: int) -> void:
	if map_mode or combat or Game.main.modal_open or view.busy:
		return
	var dir := (Game.facing + rel) % 4
	if not view.step(dir):
		if Game.mines.get(Game.pos, [false, false, false, false])[dir]:
			say("The passage %s is blocked by rubble." % Game.DIR_NAMES[dir].to_lower())
		else:
			say("A wall blocks the way %s." % Game.DIR_NAMES[dir].to_lower())


func _unhandled_key_input(e: InputEvent) -> void:
	if not e.is_pressed() or Game.main.modal_open:
		return
	if combat:
		_combat_key(e)
		return
	match e.keycode:
		KEY_W, KEY_UP: _walk(0)
		KEY_S, KEY_DOWN: _walk(2)
		KEY_A, KEY_LEFT: _turn(-1)
		KEY_D, KEY_RIGHT: _turn(1)
		KEY_Q: _walk(3)
		KEY_E: _walk(1)
		KEY_M:
			map_btn.button_pressed = not map_btn.button_pressed
			_on_map()
		_: return
	get_viewport().set_input_as_handled()


func _on_map() -> void:
	map_mode = map_btn.button_pressed
	automap.visible = map_mode
	view_rect.visible = not map_mode
	for b in masked_in_map:
		b.disabled = map_mode


func _on_close() -> void:
	if await Game.main.confirm("Do you really want to leave the mines?"):
		Game.main.goto("world")


func _on_save() -> void:
	if Game.save_game("dungeon"):
		say("Game saved.")
	else:
		say("Could not save the game!")


func _on_examine() -> void:
	var open := []
	for d in 4:
		if Game.exit_open(Game.pos, d):
			open.append(Game.DIR_NAMES[d].to_lower())
	say("You search around. Passages lead %s." % ", ".join(open))


func _on_sleep() -> void:
	if Game.my_random(1, 100) <= 30:
		say("The party settles down to rest... but something finds you first!")
		start_combat(Combat.new(Game.depth()))
		return
	var hungry := []
	for c in Game.party:
		var gain := mini(c.max_hits - c.hits, c.health / 2)
		c.hits += gain
		c.health -= gain * 2
		c.magic = c.max_magic
		if c.hits < c.max_hits:
			hungry.append(c.name)
	_refresh_party()
	say("The party rests. Wounds close and mana returns.")
	if not hungry.is_empty():
		say("%s too hungry to heal fully - eat something." % (" and ".join(hungry) + (" is" if hungry.size() == 1 else " are")))


# ---------------------------------------------------------------- combat UI state

## Exploring: combat buttons masked (MaskCombat), the rest usable.
func _explore_ui() -> void:
	for k in act_buttons:
		act_buttons[k].disabled = true
	defaults_btn.disabled = true
	auto_btn.disabled = true
	tactics_btn.disabled = Game.party.is_empty()
	for b in masked_in_map:
		b.disabled = map_mode
	map_btn.disabled = false
	status_label.text = "No enemies in sight."
	status_label.add_theme_color_override("font_color", Ui.DIM)


func start_combat(c: Combat) -> void:
	combat = c
	orders = {}
	auto = false
	auto_btn.set_pressed_no_signal(false)
	if map_mode:
		map_btn.button_pressed = false
		_on_map()
	for b in masked_in_map:
		b.disabled = true
	map_btn.disabled = true
	auto_btn.disabled = false
	enemy_panel.combat = c
	enemy_panel.visible = true
	status_label.add_theme_color_override("font_color", Ui.TEXT)
	say("Something stirs in the dark! You face %s." % c.describe())
	for ch in Game.party:
		var w := c.weapon_info(ch)
		if w.name == "fists" and not c.weapon_slots(ch).is_empty():
			say("(%s has no weapon in hand - use Equip.)" % ch.name)
	_new_round()


func _new_round() -> void:
	orders = {}
	_refresh_party()
	if auto:
		_fill_defaults(0)
		_resolve()
		return
	_next_character(-1)


func _next_character(after: int) -> void:
	for i in range(after + 1, Game.party.size()):
		if Game.party[i].hits > 0:
			cur = i
			_show_command()
			return
	_resolve()


func _show_command() -> void:
	phase = "command"
	pending = ""
	enemy_panel.targeting = false
	for i in ports.size():
		ports[i].highlight = i == cur
	var av := combat.available(cur)
	for k in act_buttons:
		act_buttons[k].disabled = not av[k]
	var sp := Game.spell_for(Game.party[cur])
	act_buttons["spells"].tooltip_text = ("%s (%d mana): %s (S)" % [sp.name, sp.cost, sp.desc]) if not sp.is_empty() \
		else "%s knows no spells" % Game.party[cur].name
	defaults_btn.disabled = false
	tactics_btn.disabled = false
	status_label.text = "%s: choose an action." % Game.party[cur].name
	_refresh_party()


func _lock_buttons() -> void:
	for k in act_buttons:
		act_buttons[k].disabled = true
	defaults_btn.disabled = true
	tactics_btn.disabled = true


func _on_action(act: String) -> void:
	if phase != "command" or Game.main.modal_open:
		return
	var c: Dictionary = Game.party[cur]
	match act:
		"use", "equip":
			var slots := combat.food_slots(c) if act == "use" else combat.weapon_slots(c)
			var names := slots.map(func(s): return Game.item(c.items[s]).name)
			var q := "What should %s eat or drink?" % c.name if act == "use" else "Which weapon should %s ready?" % c.name
			var pick: int = await Game.main.choose(q, names)
			if pick < 0 or combat == null:
				return
			orders[cur] = {"act": act, "slot": slots[pick], "item": c.items[slots[pick]]}
			_commit()
		"attack", "spells", "turn":
			var kind := combat.target_kind(cur, act)
			if kind == "enemy":
				var choices := combat.undead_groups() if act == "turn" else combat.alive_groups()
				if choices.size() == 1:
					orders[cur] = {"act": act, "target": choices[0]}
					_commit()
					return
				enemy_panel.filter = combat.is_undead if act == "turn" else Callable()
			_ask_target(act, kind)
		_:
			orders[cur] = {"act": act}
			_commit()


func _ask_target(act: String, kind: String) -> void:
	phase = "target"
	pending = act
	_lock_buttons()
	if kind == "enemy":
		enemy_panel.targeting = true
		status_label.text = "%s: click the monsters to %s. (Esc to go back)" % [Game.party[cur].name, "attack" if act == "attack" else "target"]
	else:
		status_label.text = "%s: click the portrait of the one to heal. (Esc to go back)" % Game.party[cur].name


func _on_group_picked(gi: int) -> void:
	if phase != "target":
		return
	orders[cur] = {"act": pending, "target": gi}
	enemy_panel.targeting = false
	_commit()


func _on_portrait_input(e: InputEvent, i: int) -> void:
	if phase != "target" or enemy_panel.targeting:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		orders[cur] = {"act": pending, "target": i, "ally": true}
		_commit()


func _commit() -> void:
	_refresh_party()
	_next_character(cur)


## Esc: cancel targeting, or take back the previous character's order.
func _back() -> void:
	if phase == "target":
		_show_command()
		return
	if phase != "command":
		return
	for i in range(cur - 1, -1, -1):
		if Game.party[i].hits > 0:
			orders.erase(i)
			cur = i
			_show_command()
			return


func _combat_key(e: InputEvent) -> void:
	var k: int = e.keycode
	if phase == "resolve":
		if k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			fast = true
			get_viewport().set_input_as_handled()
		return
	if k == KEY_ESCAPE:
		_back()
	elif k == KEY_D and phase == "command":
		_on_defaults()
	elif ACT_KEYS.has(k) and phase == "command" and not act_buttons[ACT_KEYS[k]].disabled:
		_on_action(ACT_KEYS[k])
	else:
		return
	get_viewport().set_input_as_handled()


func _fill_defaults(from: int) -> void:
	for i in range(from, Game.party.size()):
		if Game.party[i].hits > 0 and not orders.has(i):
			orders[i] = combat.default_order(i)


func _on_defaults() -> void:
	if phase != "command" and phase != "target":
		return
	enemy_panel.targeting = false
	_fill_defaults(cur)
	_resolve()


func _on_tactics() -> void:
	if phase == "resolve":
		return
	await Game.main.tactics()


func _on_auto() -> void:
	auto = auto_btn.button_pressed
	if auto and (phase == "command" or phase == "target"):
		_on_defaults()
	elif auto:
		fast = true


# ---------------------------------------------------------------- combat round

func _pause(t: float) -> void:
	var d := t
	if auto:
		d = 0.07
	elif fast:
		d = 0.0
	if d > 0.0:
		await get_tree().create_timer(d).timeout
	else:
		await get_tree().process_frame


func _resolve() -> void:
	phase = "resolve"
	fast = false
	_lock_buttons()
	enemy_panel.targeting = false
	for p in ports:
		p.highlight = false
	_refresh_party()
	status_label.text = "Auto-combat: untoggle Auto to take over." if auto else "Fighting... (click the log or press Space to hurry)"
	var list := combat.begin_round(orders)
	await _pause(0.3)
	for a in list:
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
			say(l)
		_refresh_party()
		await _pause(0.75)
		if a.side == "p":
			ports[a.i].highlight = false
	if not is_inside_tree():
		return
	combat.end_round()
	var result := combat.outcome()
	if result == "":
		_new_round()
	else:
		_end_combat(result)


func _end_combat(result: String) -> void:
	phase = ""
	var c := combat
	match result:
		"won":
			var lines := c.rewards()
			for l in lines:
				say(l)
			combat = null
			_refresh_party()
			await Game.main.message("\n".join(lines))
		"fled":
			say("You get away. Your hearts are still pounding.")
			combat = null
		"lost":
			combat = null
			say("The last of the party falls...")
			await _pause(0.6)
			await Game.main.message("The party has fallen.\nYou wake up at the inn in %s, bruised and robbed of half your coins." % Game.city.name)
			Game.party_defeated()
			Game.main.goto("inn")
			return
	steps_quiet = 0
	enemy_panel.visible = false
	enemy_panel.combat = null
	auto = false
	auto_btn.set_pressed_no_signal(false)
	for p in ports:
		p.highlight = false
	_refresh_party()
	_explore_ui()
