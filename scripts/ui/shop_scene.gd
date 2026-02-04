extends Control
## ShopScene - Buy items, training, and moves

const MoveLibrary = preload("res://scripts/battle/move_library.gd")

@onready var gold_label: Label = $VBoxContainer/GoldLabel
@onready var tabs: TabContainer = $VBoxContainer/TabContainer
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var leave_btn: Button = $VBoxContainer/LeaveBtn

# Shop data
var consumables: Array = [
	{"name": "Heal Potion", "cost": 30, "effect": "heal_50", "desc": "Restore 50 HP"},
	{"name": "Energy Drink", "cost": 25, "effect": "stamina_boost", "desc": "+10 max stamina this run"},
	{"name": "Full Heal", "cost": 80, "effect": "heal_full", "desc": "Restore all HP"},
]

var training_items: Array = [
	{"name": "STR Training", "cost": 50, "effect": "stat_strength", "desc": "Strength +1"},
	{"name": "AGI Training", "cost": 50, "effect": "stat_agility", "desc": "Agility +1"},
	{"name": "VIT Training", "cost": 50, "effect": "stat_vitality", "desc": "Vitality +1"},
	{"name": "TEC Training", "cost": 50, "effect": "stat_technique", "desc": "Technique +1"},
	{"name": "WIL Training", "cost": 50, "effect": "stat_willpower", "desc": "Willpower +1"},
	{"name": "INT Training", "cost": 50, "effect": "stat_intuition", "desc": "Intuition +1"},
]

var available_moves: Array = []


func _ready() -> void:
	_generate_move_shop()
	_update_gold_display()
	_setup_tabs()
	leave_btn.pressed.connect(_on_leave_pressed)


func _generate_move_shop() -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	# Get moves player doesn't have
	var all_moves = MoveLibrary.get_basic_moves() + MoveLibrary.get_skill_moves()
	var owned_names = []
	for m in run.available_moves:
		owned_names.append(m.move_name)

	available_moves.clear()
	for move in all_moves:
		if not owned_names.has(move.move_name):
			# Calculate price based on move type and power
			var base_price = 40
			if move.move_type == 1:  # SKILL
				base_price = 80
			base_price += int(move.damage_multiplier * 20)
			available_moves.append({
				"move": move,
				"cost": base_price
			})

	# Shuffle and pick 3
	available_moves.shuffle()
	if available_moves.size() > 3:
		available_moves = available_moves.slice(0, 3)


func _update_gold_display() -> void:
	var run = RunManager.get_current_run()
	if run:
		gold_label.text = "Gold: " + str(run.gold)


func _setup_tabs() -> void:
	# Clear existing tabs
	for child in tabs.get_children():
		child.queue_free()

	# Consumables tab
	var consumables_container = _create_items_tab(consumables, "consumable")
	consumables_container.name = "Items"
	tabs.add_child(consumables_container)

	# Training tab
	var training_container = _create_items_tab(training_items, "training")
	training_container.name = "Training"
	tabs.add_child(training_container)

	# Moves tab
	var moves_container = _create_moves_tab()
	moves_container.name = "Moves"
	tabs.add_child(moves_container)


func _create_items_tab(items: Array, category: String) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for item in items:
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label = Label.new()
		name_label.text = item["name"] + " - " + str(item["cost"]) + "g"
		info_vbox.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = item["desc"]
		desc_label.modulate = Color(0.7, 0.7, 0.7)
		info_vbox.add_child(desc_label)

		hbox.add_child(info_vbox)

		var btn = Button.new()
		btn.text = "BUY"
		btn.custom_minimum_size.x = 50
		btn.pressed.connect(_on_buy_item.bind(item, category))
		hbox.add_child(btn)

		vbox.add_child(hbox)
		vbox.add_child(HSeparator.new())

	scroll.add_child(vbox)
	return scroll


func _create_moves_tab() -> ScrollContainer:
	var scroll = ScrollContainer.new()
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if available_moves.is_empty():
		var label = Label.new()
		label.text = "No new moves available!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
	else:
		for item in available_moves:
			var move = item["move"]
			var cost = item["cost"]

			var hbox = HBoxContainer.new()
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var info_vbox = VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var name_label = Label.new()
			var type_str = ["BASIC", "SKILL", "ULTIMATE"][move.move_type]
			name_label.text = move.move_name + " [" + type_str + "] - " + str(cost) + "g"
			info_vbox.add_child(name_label)

			var desc_label = Label.new()
			desc_label.text = move.description
			desc_label.modulate = Color(0.7, 0.7, 0.7)
			info_vbox.add_child(desc_label)

			var stats_label = Label.new()
			stats_label.text = "DMG: x%.1f | Stamina: %.0f" % [move.damage_multiplier, move.stamina_cost]
			stats_label.modulate = Color(0.6, 0.8, 0.6)
			info_vbox.add_child(stats_label)

			hbox.add_child(info_vbox)

			var btn = Button.new()
			btn.text = "BUY"
			btn.custom_minimum_size.x = 50
			btn.pressed.connect(_on_buy_move.bind(item))
			hbox.add_child(btn)

			vbox.add_child(hbox)
			vbox.add_child(HSeparator.new())

	scroll.add_child(vbox)
	return scroll


func _on_buy_item(item: Dictionary, _category: String) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if not run.spend_gold(item["cost"]):
		result_label.text = "Not enough gold!"
		return

	# Apply effect
	match item["effect"]:
		"heal_50":
			run.heal(50)
			result_label.text = "Healed 50 HP!"
		"heal_full":
			run.heal(run.max_hp)
			result_label.text = "Fully healed!"
		"stamina_boost":
			# Would need to implement this in run_data
			result_label.text = "Stamina boosted!"
		"stat_strength":
			run.add_stat_point("strength")
			result_label.text = "STR +1!"
		"stat_agility":
			run.add_stat_point("agility")
			result_label.text = "AGI +1!"
		"stat_vitality":
			run.add_stat_point("vitality")
			result_label.text = "VIT +1!"
		"stat_technique":
			run.add_stat_point("technique")
			result_label.text = "TEC +1!"
		"stat_willpower":
			run.add_stat_point("willpower")
			result_label.text = "WIL +1!"
		"stat_intuition":
			run.add_stat_point("intuition")
			result_label.text = "INT +1!"

	_update_gold_display()


func _on_buy_move(item: Dictionary) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if not run.spend_gold(item["cost"]):
		result_label.text = "Not enough gold!"
		return

	var move = item["move"]
	if run.learn_move(move):
		# Auto-equip if slot available
		if run.equipped_moves.size() < 4:
			run.equip_move(move)
			result_label.text = "Learned and equipped " + move.move_name + "!"
		else:
			result_label.text = "Learned " + move.move_name + "!"

		# Remove from available
		available_moves.erase(item)
		_setup_tabs()  # Refresh display
	else:
		result_label.text = "Already know this move!"
		run.gold += item["cost"]  # Refund

	_update_gold_display()


func _on_leave_pressed() -> void:
	RunManager.on_node_action_completed()
