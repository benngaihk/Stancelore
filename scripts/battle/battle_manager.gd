extends Node
## BattleManager - Controls battle flow, camera effects, and win/lose conditions

const FighterStatsScript = preload("res://scripts/battle/fighter_stats.gd")

var player_fighter: FighterController = null
var enemy_fighter: FighterController = null
var camera: Camera2D = null
var combo_label: Label = null

# Screen shake
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

# Whether this is a roguelike run battle or standalone
var is_run_battle: bool = false

# Combo display
var displayed_combo: int = 0


func _ready() -> void:
	# Wait one frame for scene to be fully ready
	await get_tree().process_frame
	_initialize_battle()


func _initialize_battle() -> void:
	# Find fighters
	player_fighter = get_parent().get_node_or_null("PlayerFighter")
	enemy_fighter = get_parent().get_node_or_null("EnemyFighter")
	camera = get_parent().get_node_or_null("Camera2D")

	if camera:
		original_camera_offset = camera.offset

	# Check if we're in a roguelike run
	var run = RunManager.get_current_run()
	is_run_battle = run != null and run.is_run_active

	# Set up fighter stats
	if is_run_battle:
		_setup_run_battle(run)
	else:
		_setup_standalone_battle()

	# Set targets
	if player_fighter and enemy_fighter:
		player_fighter.target = enemy_fighter
		enemy_fighter.target = player_fighter

		# Get UI bars
		_setup_ui_bars()

		# Start battle
		GameManager.start_battle(player_fighter, enemy_fighter)

	# Connect signals
	EventBus.screen_shake_requested.connect(_on_screen_shake_requested)
	EventBus.fighter_defeated.connect(_on_fighter_defeated)


func _setup_run_battle(run: Resource) -> void:
	# Set player stats from run
	if player_fighter and run.fighter_stats:
		player_fighter.stats = run.fighter_stats
		player_fighter._initialize_stats()
		# Use run's current HP
		player_fighter.hp = run.current_hp
		player_fighter.max_hp = run.max_hp

	# Create enemy based on difficulty
	if enemy_fighter:
		var enemy_stats = RunManager.create_enemy_stats(RunManager.pending_battle_difficulty)
		enemy_fighter.stats = enemy_stats
		enemy_fighter._initialize_stats()

		# Elite/Boss bonus
		if RunManager.pending_battle_is_elite:
			enemy_fighter.max_hp *= 1.5
			enemy_fighter.hp = enemy_fighter.max_hp
		if RunManager.pending_battle_is_boss:
			enemy_fighter.max_hp *= 2.0
			enemy_fighter.hp = enemy_fighter.max_hp


func _setup_standalone_battle() -> void:
	# Use default balanced stats for both
	if player_fighter and player_fighter.stats == null:
		player_fighter.stats = FighterStatsScript.create_balanced()
		player_fighter._initialize_stats()

	if enemy_fighter and enemy_fighter.stats == null:
		enemy_fighter.stats = FighterStatsScript.create_balanced()
		enemy_fighter._initialize_stats()


func _setup_ui_bars() -> void:
	var ui = get_parent().get_node_or_null("UI/BattleUI")
	if not ui:
		return

	# HP bars
	player_fighter.hp_bar = ui.get_node_or_null("PlayerHPBar")
	enemy_fighter.hp_bar = ui.get_node_or_null("EnemyHPBar")
	# Stamina bars
	player_fighter.stamina_bar = ui.get_node_or_null("PlayerStaminaBar")
	enemy_fighter.stamina_bar = ui.get_node_or_null("EnemyStaminaBar")
	# Combo label
	combo_label = ui.get_node_or_null("ComboLabel")

	# Initialize HP bar values
	if player_fighter.hp_bar:
		player_fighter.hp_bar.max_value = player_fighter.max_hp
		player_fighter.hp_bar.value = player_fighter.hp
	if enemy_fighter.hp_bar:
		enemy_fighter.hp_bar.max_value = enemy_fighter.max_hp
		enemy_fighter.hp_bar.value = enemy_fighter.hp

	# Initialize stamina bar values
	if player_fighter.stamina_bar:
		player_fighter.stamina_bar.max_value = player_fighter.max_stamina
		player_fighter.stamina_bar.value = player_fighter.stamina
	if enemy_fighter.stamina_bar:
		enemy_fighter.stamina_bar.max_value = enemy_fighter.max_stamina
		enemy_fighter.stamina_bar.value = enemy_fighter.stamina


func _process(delta: float) -> void:
	# Debug: Press ESC to instantly win (for testing)
	if Input.is_action_just_pressed("ui_cancel"):
		if enemy_fighter and enemy_fighter.hp > 0:
			enemy_fighter.hp = 0
			EventBus.fighter_defeated.emit(enemy_fighter)

	# Update combo display
	_update_combo_display()

	# Handle screen shake
	if shake_timer > 0:
		shake_timer -= delta
		if camera:
			camera.offset = original_camera_offset + Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
		if shake_timer <= 0:
			if camera:
				camera.offset = original_camera_offset


func _update_combo_display() -> void:
	if not combo_label or not player_fighter:
		return

	var combo = player_fighter.combo_count
	if combo >= 2:
		combo_label.text = str(combo) + " HIT!"
		combo_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		combo_label.text = ""


func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration


func _on_fighter_defeated(fighter: FighterController) -> void:
	var winner = enemy_fighter if fighter == player_fighter else player_fighter
	GameManager.end_battle(winner)

	# Show result then handle aftermath
	await _show_result(winner)

	if is_run_battle:
		_handle_run_battle_end(winner == player_fighter)
	else:
		_restart_battle()


func _handle_run_battle_end(player_won: bool) -> void:
	var run = RunManager.get_current_run()

	if player_won:
		# Save player's current HP to run
		if run and player_fighter:
			run.current_hp = player_fighter.hp
		RunManager.on_battle_won()
	else:
		RunManager.on_battle_lost()


func _show_result(winner: FighterController) -> void:
	var ui = get_parent().get_node_or_null("UI/BattleUI")
	if not ui:
		return

	# Create result label
	var result_label = Label.new()
	result_label.name = "ResultLabel"

	if winner == player_fighter:
		result_label.text = "YOU WIN!"
		result_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		result_label.text = "YOU LOSE"
		result_label.add_theme_color_override("font_color", Color.RED)

	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.set_anchors_preset(Control.PRESET_CENTER)
	result_label.position = Vector2(192 - 50, 108 - 20)
	result_label.size = Vector2(100, 40)

	ui.add_child(result_label)

	# Wait before continuing
	await get_tree().create_timer(2.0).timeout


func _restart_battle() -> void:
	get_tree().reload_current_scene()
