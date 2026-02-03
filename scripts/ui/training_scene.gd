extends Control
## TrainingScene - Upgrade stats or learn new moves

const MoveLibrary = preload("res://scripts/battle/move_library.gd")

@onready var tabs_container: TabContainer = $VBoxContainer/TabContainer
@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var back_button: Button = $VBoxContainer/BackButton

# Stats tab
var stats_container: VBoxContainer
var stat_names: Array = ["strength", "agility", "vitality", "technique", "willpower", "intuition"]
var stat_labels: Array = ["STR", "AGI", "VIT", "TEC", "WIL", "INT"]
var stat_descriptions: Array = [
	"Damage output",
	"Speed & evasion",
	"HP & defense",
	"Crit & combos",
	"Recovery & clutch",
	"Counter & predict"
]

# Moves tab
var moves_container: VBoxContainer
var reward_move: Resource = null


func _ready() -> void:
	_setup_tabs()
	_setup_stats_tab()
	_setup_moves_tab()

	if back_button:
		back_button.pressed.connect(_on_back_pressed)


func _setup_tabs() -> void:
	if tabs_container:
		return

	# Create tab container if not in scene
	tabs_container = TabContainer.new()
	tabs_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$VBoxContainer.add_child(tabs_container)
	$VBoxContainer.move_child(tabs_container, 0)


func _setup_stats_tab() -> void:
	var run = RunManager.get_current_run()
	if run == null or run.fighter_stats == null:
		return

	# Create stats container
	stats_container = VBoxContainer.new()
	stats_container.name = "Stats Training"

	var title = Label.new()
	title.text = "Choose a stat to upgrade (+1)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(title)

	stats_container.add_child(HSeparator.new())

	for i in range(stat_names.size()):
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label = Label.new()
		var stat_value = run.fighter_stats.get(stat_names[i])
		label.text = stat_labels[i] + ": " + str(stat_value) + "/10"
		label.custom_minimum_size.x = 80
		hbox.add_child(label)

		var desc = Label.new()
		desc.text = "(" + stat_descriptions[i] + ")"
		desc.modulate = Color(0.7, 0.7, 0.7)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc)

		var btn = Button.new()
		btn.text = "+1"
		btn.custom_minimum_size.x = 40
		btn.disabled = stat_value >= 10
		btn.pressed.connect(_on_stat_upgrade.bind(stat_names[i]))
		hbox.add_child(btn)

		stats_container.add_child(hbox)

	tabs_container.add_child(stats_container)


func _setup_moves_tab() -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	moves_container = VBoxContainer.new()
	moves_container.name = "Learn Move"

	var title = Label.new()
	title.text = "Learn a new move"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_container.add_child(title)

	moves_container.add_child(HSeparator.new())

	# Get a random learnable move
	reward_move = MoveLibrary.get_random_learnable_move(run.available_moves)

	if reward_move:
		var move_panel = _create_move_display(reward_move)
		moves_container.add_child(move_panel)

		var learn_btn = Button.new()
		learn_btn.text = "Learn " + reward_move.move_name
		learn_btn.pressed.connect(_on_learn_move)
		moves_container.add_child(learn_btn)
	else:
		var no_moves = Label.new()
		no_moves.text = "You've learned all available moves!"
		no_moves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		moves_container.add_child(no_moves)

	# Show current equipped moves
	moves_container.add_child(HSeparator.new())

	var equipped_label = Label.new()
	equipped_label.text = "Equipped Moves (" + str(run.equipped_moves.size()) + "/4):"
	moves_container.add_child(equipped_label)

	for move in run.equipped_moves:
		var move_row = _create_equipped_move_row(move)
		moves_container.add_child(move_row)

	tabs_container.add_child(moves_container)


func _create_move_display(move: Resource) -> VBoxContainer:
	var panel = VBoxContainer.new()

	var name_label = Label.new()
	name_label.text = move.move_name
	var type_str = ["BASIC", "SKILL", "ULTIMATE"][move.move_type]
	name_label.text += " [" + type_str + "]"
	panel.add_child(name_label)

	var desc = Label.new()
	desc.text = move.description
	desc.modulate = Color(0.8, 0.8, 0.8)
	panel.add_child(desc)

	var stats_text = "DMG: x%.1f | Stamina: %.0f | Speed: %.1f" % [
		move.damage_multiplier,
		move.stamina_cost,
		1.0 / move.startup_multiplier
	]
	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.modulate = Color(0.7, 0.9, 0.7)
	panel.add_child(stats_label)

	if move.cooldown > 0:
		var cd_label = Label.new()
		cd_label.text = "Cooldown: %.1fs" % move.cooldown
		cd_label.modulate = Color(0.9, 0.7, 0.7)
		panel.add_child(cd_label)

	return panel


func _create_equipped_move_row(move: Resource) -> HBoxContainer:
	var row = HBoxContainer.new()

	var name_label = Label.new()
	name_label.text = "- " + move.move_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var unequip_btn = Button.new()
	unequip_btn.text = "Unequip"
	unequip_btn.pressed.connect(_on_unequip_move.bind(move.move_name))
	row.add_child(unequip_btn)

	return row


func _on_stat_upgrade(stat_name: String) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if run.add_stat_point(stat_name):
		info_label.text = stat_name.to_upper() + " upgraded!"
		await get_tree().create_timer(1.0).timeout
		RunManager.on_node_action_completed()


func _on_learn_move() -> void:
	var run = RunManager.get_current_run()
	if run == null or reward_move == null:
		return

	if run.learn_move(reward_move):
		# Auto-equip if slot available
		if run.equipped_moves.size() < 4:
			run.equip_move(reward_move)
			info_label.text = "Learned and equipped " + reward_move.move_name + "!"
		else:
			info_label.text = "Learned " + reward_move.move_name + "!"

		await get_tree().create_timer(1.0).timeout
		RunManager.on_node_action_completed()


func _on_unequip_move(move_name: String) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if run.equipped_moves.size() <= 1:
		info_label.text = "Must have at least 1 move equipped!"
		return

	if run.unequip_move(move_name):
		info_label.text = "Unequipped " + move_name
		# Refresh the display
		_refresh_moves_display()


func _refresh_moves_display() -> void:
	# Remove and recreate moves tab
	if moves_container:
		moves_container.queue_free()
	await get_tree().process_frame
	_setup_moves_tab()


func _on_back_pressed() -> void:
	RunManager.on_node_action_completed()
