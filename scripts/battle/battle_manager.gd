extends Node
## BattleManager - Controls battle flow, camera effects, and win/lose conditions

const FighterStatsScript = preload("res://scripts/battle/fighter_stats.gd")

var player_fighter: FighterController = null
var enemy_fighter: FighterController = null
var camera: Camera2D = null
var combo_label: Label = null
var player_move_label: Label = null
var enemy_move_label: Label = null
var action_log: Label = null

# Screen shake
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

# Whether this is a roguelike run battle or standalone
var is_run_battle: bool = false

# Combo display
var displayed_combo: int = 0

# Battle performance tracking
var max_combo_achieved: int = 0


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
	EventBus.fighter_attacked.connect(_on_fighter_attacked)
	EventBus.fighter_hit.connect(_on_fighter_hit)
	EventBus.fighter_blocked.connect(_on_fighter_blocked)
	EventBus.fighter_evaded.connect(_on_fighter_evaded)
	EventBus.fighter_state_changed.connect(_on_fighter_state_changed)


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
	# Labels
	combo_label = ui.get_node_or_null("ComboLabel")
	player_move_label = ui.get_node_or_null("PlayerMoveLabel")
	enemy_move_label = ui.get_node_or_null("EnemyMoveLabel")
	action_log = ui.get_node_or_null("ActionLog")

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
	if combo > max_combo_achieved:
		max_combo_achieved = combo

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

		# Report battle performance to RunManager
		RunManager.last_battle_max_combo = max_combo_achieved
		RunManager.last_battle_hp_ratio = player_fighter.get_hp_ratio() if player_fighter else 1.0

		RunManager.on_battle_won()
	else:
		RunManager.on_battle_lost()


func _show_result(winner: FighterController) -> void:
	var ui = get_parent().get_node_or_null("UI/BattleUI")
	if not ui:
		return

	# Create result container
	var result_container = VBoxContainer.new()
	result_container.name = "ResultContainer"
	result_container.set_anchors_preset(Control.PRESET_CENTER)
	result_container.position = Vector2(192 - 80, 108 - 50)
	result_container.size = Vector2(160, 100)

	# Result label
	var result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if winner == player_fighter:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color.RED)

	result_container.add_child(result_label)

	# Show rewards if player won and in roguelike run
	if winner == player_fighter and is_run_battle:
		# Report performance first
		RunManager.last_battle_max_combo = max_combo_achieved
		RunManager.last_battle_hp_ratio = player_fighter.get_hp_ratio() if player_fighter else 1.0
		var rewards = RunManager._calculate_battle_rewards()

		var gold_label = Label.new()
		gold_label.text = "Gold: +" + str(rewards.gold - rewards.bonus_gold)
		gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gold_label.add_theme_color_override("font_color", Color.YELLOW)
		result_container.add_child(gold_label)

		if rewards.combo_bonus > 0:
			var combo_bonus_label = Label.new()
			combo_bonus_label.text = "Combo Bonus: +" + str(rewards.combo_bonus)
			combo_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			combo_bonus_label.add_theme_color_override("font_color", Color.ORANGE)
			result_container.add_child(combo_bonus_label)

		if rewards.hp_bonus > 0:
			var hp_bonus_label = Label.new()
			hp_bonus_label.text = "HP Bonus: +" + str(rewards.hp_bonus)
			hp_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hp_bonus_label.add_theme_color_override("font_color", Color.CYAN)
			result_container.add_child(hp_bonus_label)

		if max_combo_achieved >= 3:
			var combo_label = Label.new()
			combo_label.text = "Max Combo: " + str(max_combo_achieved)
			combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			combo_label.modulate = Color(0.8, 0.8, 0.8)
			result_container.add_child(combo_label)

	ui.add_child(result_container)

	# Wait before continuing
	await get_tree().create_timer(2.5).timeout


func _restart_battle() -> void:
	get_tree().reload_current_scene()


func _on_fighter_attacked(attacker: FighterController, _target: FighterController) -> void:
	var move_name = "Attack"
	if attacker.current_move:
		move_name = attacker.current_move.move_name

	if attacker == player_fighter:
		if player_move_label:
			player_move_label.text = move_name
			player_move_label.add_theme_color_override("font_color", Color.CYAN)
			_fade_label(player_move_label)
	else:
		if enemy_move_label:
			enemy_move_label.text = move_name
			enemy_move_label.add_theme_color_override("font_color", Color.ORANGE)
			_fade_label(enemy_move_label)


func _on_fighter_hit(attacker: FighterController, target: FighterController, damage: float) -> void:
	if action_log:
		var attacker_name = "Player" if attacker == player_fighter else "Enemy"
		action_log.text = "%s hits for %.0f!" % [attacker_name, damage]
		action_log.add_theme_color_override("font_color", Color.WHITE)
		_fade_label(action_log)


func _on_fighter_blocked(defender: FighterController, _attacker: FighterController) -> void:
	if action_log:
		var defender_name = "Player" if defender == player_fighter else "Enemy"
		action_log.text = "%s blocked!" % defender_name
		action_log.add_theme_color_override("font_color", Color.STEEL_BLUE)
		_fade_label(action_log)


func _on_fighter_evaded(evader: FighterController, _attacker: FighterController) -> void:
	if action_log:
		var evader_name = "Player" if evader == player_fighter else "Enemy"
		action_log.text = "%s evaded!" % evader_name
		action_log.add_theme_color_override("font_color", Color.YELLOW)
		_fade_label(action_log)


func _on_fighter_state_changed(fighter: FighterController, _old_state: int, new_state: int) -> void:
	# Update move label based on state
	var label = player_move_label if fighter == player_fighter else enemy_move_label
	if not label:
		return

	match new_state:
		FighterController.State.DEFEND:
			label.text = "Guard"
			label.add_theme_color_override("font_color", Color.STEEL_BLUE)
		FighterController.State.EVADE:
			label.text = "Evade"
			label.add_theme_color_override("font_color", Color.YELLOW)
		FighterController.State.HIT:
			label.text = "Hit!"
			label.add_theme_color_override("font_color", Color.RED)
		FighterController.State.IDLE, FighterController.State.WALK:
			label.text = ""


func _fade_label(label: Label) -> void:
	# Simple fade effect using tween
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.0)
	tween.tween_interval(0.8)
	tween.tween_property(label, "modulate:a", 0.3, 0.3)
