extends Control
## DemoSettings - Simple settings UI for demo mode
## Allows adjusting player and enemy stats and moves

const FighterStatsClass = preload("res://scripts/battle/fighter_stats.gd")
const MoveLibrary = preload("res://scripts/battle/move_library.gd")

var toggle_btn: Button
var settings_panel: Panel
var is_open: bool = false

# Stat sliders
var player_sliders: Dictionary = {}
var enemy_sliders: Dictionary = {}

# Move checkboxes
var player_move_checks: Array = []
var enemy_move_checks: Array = []
var all_moves: Array = []

var battle_manager: Node = null


func _ready() -> void:
	# Create toggle button
	toggle_btn = Button.new()
	toggle_btn.text = "Settings"
	toggle_btn.size = Vector2(50, 18)
	toggle_btn.pressed.connect(_toggle_settings)
	add_child(toggle_btn)

	# Get all available moves
	all_moves = MoveLibrary.get_basic_moves() + MoveLibrary.get_skill_moves()

	# Find battle manager
	await get_tree().process_frame
	battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		battle_manager = get_parent().get_parent().get_node_or_null("BattleManager")


func _toggle_settings() -> void:
	is_open = not is_open

	if is_open:
		_create_settings_panel()
		get_tree().paused = true
	else:
		_close_settings_panel()
		get_tree().paused = false


func _create_settings_panel() -> void:
	if settings_panel:
		return

	settings_panel = Panel.new()
	settings_panel.position = Vector2(-120, 25)
	settings_panel.size = Vector2(350, 180)
	add_child(settings_panel)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(5, 5)
	scroll.size = Vector2(340, 145)
	settings_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# === Player Section ===
	var player_label = Label.new()
	player_label.text = "=== PLAYER ==="
	player_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(player_label)

	_add_stat_sliders(vbox, "Player", player_sliders)
	_add_move_checkboxes(vbox, "Player", player_move_checks)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# === Enemy Section ===
	var enemy_label = Label.new()
	enemy_label.text = "=== ENEMY ==="
	enemy_label.add_theme_color_override("font_color", Color.ORANGE)
	vbox.add_child(enemy_label)

	_add_stat_sliders(vbox, "Enemy", enemy_sliders)
	_add_move_checkboxes(vbox, "Enemy", enemy_move_checks)

	# Buttons row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var apply_btn = Button.new()
	apply_btn.text = "Apply & Restart"
	apply_btn.pressed.connect(_apply_and_restart)
	btn_row.add_child(apply_btn)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_toggle_settings)
	btn_row.add_child(close_btn)

	settings_panel.add_child(btn_row)
	btn_row.position = Vector2(100, 155)

	toggle_btn.text = "Close"

	# Load current values
	_load_current_values()


func _add_stat_sliders(parent: Control, prefix: String, sliders_dict: Dictionary) -> void:
	var stats = ["STR", "AGI", "VIT", "TEC", "WIL", "INT"]

	var grid = GridContainer.new()
	grid.columns = 6

	for stat in stats:
		var hbox = VBoxContainer.new()

		var label = Label.new()
		label.text = stat
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		hbox.add_child(label)

		var slider = HSlider.new()
		slider.min_value = 1
		slider.max_value = 10
		slider.value = 5
		slider.step = 1
		slider.custom_minimum_size = Vector2(40, 12)
		hbox.add_child(slider)

		var value_label = Label.new()
		value_label.text = "5"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 10)
		slider.value_changed.connect(func(v): value_label.text = str(int(v)))
		hbox.add_child(value_label)

		sliders_dict[stat] = slider
		grid.add_child(hbox)

	parent.add_child(grid)


func _add_move_checkboxes(parent: Control, prefix: String, checks_array: Array) -> void:
	var flow = HFlowContainer.new()
	flow.custom_minimum_size = Vector2(330, 0)

	for move in all_moves:
		var check = CheckBox.new()
		check.text = move.move_name.substr(0, 6)  # Shortened name
		check.button_pressed = true
		check.add_theme_font_size_override("font_size", 9)
		check.tooltip_text = move.move_name
		flow.add_child(check)
		checks_array.append(check)

	parent.add_child(flow)


func _close_settings_panel() -> void:
	if settings_panel:
		settings_panel.queue_free()
		settings_panel = null
	toggle_btn.text = "Settings"
	player_sliders.clear()
	enemy_sliders.clear()
	player_move_checks.clear()
	enemy_move_checks.clear()


func _load_current_values() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var enemy = get_tree().get_first_node_in_group("enemy")

	if player and player.stats:
		player_sliders["STR"].value = player.stats.strength
		player_sliders["AGI"].value = player.stats.agility
		player_sliders["VIT"].value = player.stats.vitality
		player_sliders["TEC"].value = player.stats.technique
		player_sliders["WIL"].value = player.stats.willpower
		player_sliders["INT"].value = player.stats.intuition

	if enemy and enemy.stats:
		enemy_sliders["STR"].value = enemy.stats.strength
		enemy_sliders["AGI"].value = enemy.stats.agility
		enemy_sliders["VIT"].value = enemy.stats.vitality
		enemy_sliders["TEC"].value = enemy.stats.technique
		enemy_sliders["WIL"].value = enemy.stats.willpower
		enemy_sliders["INT"].value = enemy.stats.intuition


func _apply_and_restart() -> void:
	# Create player stats
	var player_stats = FighterStatsClass.new()
	player_stats.strength = int(player_sliders["STR"].value)
	player_stats.agility = int(player_sliders["AGI"].value)
	player_stats.vitality = int(player_sliders["VIT"].value)
	player_stats.technique = int(player_sliders["TEC"].value)
	player_stats.willpower = int(player_sliders["WIL"].value)
	player_stats.intuition = int(player_sliders["INT"].value)

	# Create enemy stats
	var enemy_stats = FighterStatsClass.new()
	enemy_stats.strength = int(enemy_sliders["STR"].value)
	enemy_stats.agility = int(enemy_sliders["AGI"].value)
	enemy_stats.vitality = int(enemy_sliders["VIT"].value)
	enemy_stats.technique = int(enemy_sliders["TEC"].value)
	enemy_stats.willpower = int(enemy_sliders["WIL"].value)
	enemy_stats.intuition = int(enemy_sliders["INT"].value)

	# Get selected moves
	var player_moves = []
	var enemy_moves = []

	for i in range(player_move_checks.size()):
		if player_move_checks[i].button_pressed:
			player_moves.append(all_moves[i].duplicate())

	for i in range(enemy_move_checks.size()):
		if enemy_move_checks[i].button_pressed:
			enemy_moves.append(all_moves[i].duplicate())

	# Ensure at least some moves
	if player_moves.is_empty():
		player_moves = [all_moves[0].duplicate(), all_moves[1].duplicate()]
	if enemy_moves.is_empty():
		enemy_moves = [all_moves[0].duplicate(), all_moves[1].duplicate()]

	# Store settings in autoload for reload
	GameManager.demo_player_stats = player_stats
	GameManager.demo_enemy_stats = enemy_stats
	GameManager.demo_player_moves = player_moves
	GameManager.demo_enemy_moves = enemy_moves
	GameManager.demo_settings_active = true

	# Unpause and restart
	get_tree().paused = false
	get_tree().reload_current_scene()
