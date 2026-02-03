extends CharacterBody2D
class_name FighterController
## FighterController - Handles fighter state machine, movement, and combat

const FighterStatsClass = preload("res://scripts/battle/fighter_stats.gd")
const MoveClass = preload("res://scripts/battle/move.gd")

enum State {
	IDLE,
	WALK,
	ATTACK,
	DEFEND,
	EVADE,
	HIT,
	RECOVERY
}

# Fighter identity
@export var fighter_name: String = "Fighter"
@export var is_player_controlled: bool = false
@export var facing_right: bool = true

# Stats - now uses FighterStats resource
@export var stats: Resource = null  # FighterStats
@export var attack_range: float = 35.0
@export var base_move_speed: float = 80.0

# Derived stats (calculated from FighterStats)
var max_hp: float = 100.0
var hp: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0

# Current state
var current_state: State = State.IDLE
var target: FighterController = null

# Timers (base values, modified by stats)
var state_timer: float = 0.0
var base_attack_duration: float = 0.35
var base_defend_duration: float = 0.5
var base_evade_duration: float = 0.25
var base_hit_duration: float = 0.25
var base_recovery_duration: float = 0.2

# Combo system
var combo_count: int = 0
var combo_window: float = 0.0
const COMBO_WINDOW_DURATION: float = 0.4

# Current move being executed
var current_move: Resource = null  # Move

# Components
var ai_brain: AIBrain = null
var visual: ColorRect = null
var stick_figure: Node2D = null  # StickFigure
var hitbox: Area2D = null
var hurtbox: Area2D = null
var hp_bar: ProgressBar = null
var stamina_bar: ProgressBar = null

# Visual flash
var _flash_timer: float = 0.0
var _original_color: Color = Color.WHITE


func _ready() -> void:
	_initialize_stats()
	_setup_components()
	EventBus.fighter_state_changed.emit(self, -1, current_state)


func _initialize_stats() -> void:
	# Create default stats if not assigned
	if stats == null:
		stats = FighterStatsClass.create_balanced()

	# Calculate derived stats
	max_hp = stats.get_max_hp()
	hp = max_hp
	max_stamina = 100.0
	stamina = max_stamina


func _setup_components() -> void:
	# Get visual component
	visual = get_node_or_null("Visual")
	if visual:
		_original_color = visual.color

	# Get stick figure
	stick_figure = get_node_or_null("StickFigure")

	# Get hitbox/hurtbox
	hitbox = get_node_or_null("Hitbox")
	hurtbox = get_node_or_null("Hurtbox")

	# Connect hitbox signal
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		hitbox.monitoring = false  # Disabled by default

	# Get AI brain
	ai_brain = get_node_or_null("AIBrain")


func _process(delta: float) -> void:
	# Handle visual flash
	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0 and visual:
			visual.color = _original_color

	# Handle combo window
	if combo_window > 0:
		combo_window -= delta
		if combo_window <= 0:
			combo_count = 0


func _physics_process(delta: float) -> void:
	if not GameManager.is_battle_active():
		return

	# Regenerate stamina
	_regenerate_stamina(delta)

	# Update state timer
	state_timer -= delta

	# State machine
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DEFEND:
			_process_defend(delta)
		State.EVADE:
			_process_evade(delta)
		State.HIT:
			_process_hit(delta)
		State.RECOVERY:
			_process_recovery(delta)

	# Apply gravity and move
	if not is_on_floor():
		velocity.y += 500 * delta

	move_and_slide()

	# Clamp position to screen bounds
	global_position.x = clampf(global_position.x, 20.0, 364.0)
	global_position.y = clampf(global_position.y, 0.0, 200.0)

	# Update UI bars
	_update_ui_bars()


func _regenerate_stamina(delta: float) -> void:
	if current_state == State.IDLE:
		# Faster regen when idle
		stamina = min(max_stamina, stamina + 15.0 * delta)
	elif current_state in [State.WALK, State.DEFEND]:
		# Slower regen during other states
		stamina = min(max_stamina, stamina + 5.0 * delta)


func _update_ui_bars() -> void:
	if hp_bar:
		hp_bar.value = hp
	if stamina_bar:
		stamina_bar.value = stamina


func _process_idle(_delta: float) -> void:
	velocity.x = 0


func _process_walk(delta: float) -> void:
	if target:
		var direction = sign(target.global_position.x - global_position.x)
		var speed = base_move_speed * stats.get_attack_speed_multiplier()
		velocity.x = direction * speed
		facing_right = direction > 0
		_update_facing()

	# Update walk animation
	if stick_figure:
		_update_stick_figure_pose()

	if state_timer <= 0:
		change_state(State.IDLE)


func _process_attack(_delta: float) -> void:
	velocity.x = 0

	var attack_duration = _get_attack_duration()

	# Enable hitbox at the right moment (middle of attack)
	if hitbox and state_timer < attack_duration * 0.5 and state_timer > attack_duration * 0.3:
		hitbox.monitoring = true
	else:
		if hitbox:
			hitbox.monitoring = false

	if state_timer <= 0:
		# Open combo window
		combo_window = COMBO_WINDOW_DURATION
		change_state(State.RECOVERY)


func _process_defend(_delta: float) -> void:
	velocity.x = 0
	if state_timer <= 0:
		change_state(State.IDLE)


func _process_evade(_delta: float) -> void:
	# Move away from target
	var direction = -1 if facing_right else 1
	var speed = base_move_speed * stats.get_attack_speed_multiplier() * 2.0
	velocity.x = direction * speed

	if state_timer <= 0:
		change_state(State.IDLE)


func _process_hit(_delta: float) -> void:
	# Knockback
	var knockback_dir = -1 if facing_right else 1
	velocity.x = knockback_dir * 60

	if state_timer <= 0:
		change_state(State.RECOVERY)


func _process_recovery(_delta: float) -> void:
	velocity.x = 0
	if state_timer <= 0:
		change_state(State.IDLE)


func _get_attack_duration() -> float:
	# Faster attacks with higher AGI
	var base = base_attack_duration / stats.get_attack_speed_multiplier()
	# Apply move timing modifiers
	if current_move:
		base *= current_move.startup_multiplier
	return base


func _get_recovery_duration() -> float:
	# Faster recovery with higher WIL
	var base = base_recovery_duration / stats.get_recovery_speed()
	# Apply move recovery modifier
	if current_move:
		base *= current_move.recovery_multiplier
	return base


func _get_hit_duration() -> float:
	# Faster recovery from hits with higher WIL
	return base_hit_duration / stats.get_recovery_speed()


func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	var old_state = current_state
	current_state = new_state

	# Setup new state
	match new_state:
		State.IDLE:
			state_timer = 0
		State.WALK:
			state_timer = 0.5
		State.ATTACK:
			state_timer = _get_attack_duration()
			_update_facing_to_target()
		State.DEFEND:
			state_timer = base_defend_duration
		State.EVADE:
			state_timer = base_evade_duration
		State.HIT:
			state_timer = _get_hit_duration()
			combo_count = 0  # Reset combo when hit
			combo_window = 0
		State.RECOVERY:
			state_timer = _get_recovery_duration()

	# Disable hitbox on state change
	if hitbox:
		hitbox.monitoring = false

	EventBus.fighter_state_changed.emit(self, old_state, new_state)
	_update_visual_for_state()


func _update_facing_to_target() -> void:
	if target:
		facing_right = target.global_position.x > global_position.x
		_update_facing()


func _update_facing() -> void:
	if visual:
		visual.scale.x = 1 if facing_right else -1
	if stick_figure:
		stick_figure.scale.x = 1 if facing_right else -1


func _update_visual_for_state() -> void:
	# Update color rect (legacy)
	if visual:
		match current_state:
			State.IDLE:
				visual.color = _original_color
			State.WALK:
				visual.color = _original_color.lightened(0.1)
			State.ATTACK:
				if current_move and current_move.color_tint != Color.WHITE:
					visual.color = current_move.color_tint.lerp(_original_color, 0.4)
				else:
					visual.color = Color.RED.lerp(_original_color, 0.3)
			State.DEFEND:
				visual.color = Color.BLUE.lerp(_original_color, 0.3)
			State.EVADE:
				visual.color = Color.YELLOW.lerp(_original_color, 0.3)
			State.HIT:
				visual.color = Color.WHITE
			State.RECOVERY:
				visual.color = _original_color.darkened(0.2)

	# Update stick figure pose
	if stick_figure:
		_update_stick_figure_pose()


func can_act() -> bool:
	return current_state in [State.IDLE, State.WALK]


func _update_stick_figure_pose() -> void:
	if not stick_figure:
		return

	var StickFigure = preload("res://scripts/battle/stick_figure.gd")

	match current_state:
		State.IDLE:
			stick_figure.set_pose(StickFigure.Pose.IDLE)
		State.WALK:
			# Alternate between walk poses
			var walk_phase = int(state_timer * 4) % 2
			if walk_phase == 0:
				stick_figure.set_pose(StickFigure.Pose.WALK_1)
			else:
				stick_figure.set_pose(StickFigure.Pose.WALK_2)
		State.ATTACK:
			if current_move:
				var pose = stick_figure.get_pose_for_move(current_move.move_name)
				stick_figure.set_pose(pose)
			else:
				stick_figure.set_pose(StickFigure.Pose.JAB)
		State.DEFEND:
			stick_figure.set_pose(StickFigure.Pose.DEFEND)
		State.EVADE:
			stick_figure.set_pose(StickFigure.Pose.EVADE)
		State.HIT:
			stick_figure.set_pose(StickFigure.Pose.HIT)
		State.RECOVERY:
			stick_figure.set_pose(StickFigure.Pose.RECOVERY)


func has_stamina(cost: float) -> bool:
	return stamina >= cost


func consume_stamina(cost: float) -> void:
	stamina = max(0, stamina - cost)


func do_attack(move: Resource = null) -> void:
	if not can_act():
		return

	var stamina_cost = 10.0
	if move:
		stamina_cost = move.stamina_cost

	if not has_stamina(stamina_cost):
		return

	consume_stamina(stamina_cost)
	current_move = move

	# Increment combo if within window
	if combo_window > 0:
		combo_count += 1
	else:
		combo_count = 1

	change_state(State.ATTACK)
	EventBus.fighter_attacked.emit(self, target)


func do_defend() -> void:
	if can_act() and has_stamina(5.0):
		consume_stamina(5.0)
		change_state(State.DEFEND)


func do_evade() -> void:
	if can_act() and has_stamina(15.0):
		consume_stamina(15.0)
		change_state(State.EVADE)


func do_walk() -> void:
	if can_act():
		change_state(State.WALK)


func calculate_damage() -> float:
	var base_damage = stats.get_base_damage()

	# Apply move damage if using a move
	if current_move:
		base_damage *= current_move.damage_multiplier

	# Apply combo bonus (10% per combo hit, up to 50%)
	var combo_bonus = 1.0 + min(combo_count * 0.1, 0.5)
	base_damage *= combo_bonus

	# Apply low HP bonus (willpower)
	base_damage *= stats.get_low_hp_bonus(get_hp_ratio())

	# Check for critical hit
	if randf() < stats.get_crit_chance():
		base_damage *= 1.5
		# TODO: Emit crit event for visual feedback

	return base_damage


func take_damage(damage: float, attacker: FighterController) -> void:
	# Check for evade
	if current_state == State.EVADE:
		EventBus.fighter_evaded.emit(self, attacker)
		return

	# Check for block
	if current_state == State.DEFEND:
		# Defense reduces damage based on VIT
		var defense_reduction = 0.7 + stats.get_defense_multiplier()
		damage *= (1.0 - defense_reduction)
		EventBus.fighter_blocked.emit(self, attacker)
		# Still take chip damage but don't get staggered
		var old_hp = hp
		hp = max(0, hp - damage)
		EventBus.fighter_hp_changed.emit(self, old_hp, hp)
		if hp <= 0:
			EventBus.fighter_defeated.emit(self)
		return

	# Apply defense from VIT
	damage *= (1.0 - stats.get_defense_multiplier())

	var old_hp = hp
	hp = max(0, hp - damage)

	EventBus.fighter_hp_changed.emit(self, old_hp, hp)
	EventBus.fighter_hit.emit(attacker, self, damage)

	# Spawn damage number
	_spawn_damage_number(damage)

	# Request hit stop and screen shake (scaled by damage)
	var hit_stop_duration = 0.04 + (damage / 100.0) * 0.03
	var shake_intensity = 2.0 + (damage / 20.0)
	EventBus.hit_stop_requested.emit(hit_stop_duration)
	EventBus.screen_shake_requested.emit(shake_intensity, 0.1)

	# Visual flash
	_flash_timer = 0.1
	if visual:
		visual.color = Color.WHITE

	# Change to hit state
	change_state(State.HIT)

	# Check for defeat
	if hp <= 0:
		EventBus.fighter_defeated.emit(self)


func get_distance_to_target() -> float:
	if target:
		return abs(global_position.x - target.global_position.x)
	return 999.0


func get_hp_ratio() -> float:
	return hp / max_hp


func get_stamina_ratio() -> float:
	return stamina / max_stamina


func _spawn_damage_number(damage: float) -> void:
	var DamageNumberScript = preload("res://scripts/battle/damage_number.gd")
	var dmg_num = DamageNumberScript.create(damage, Vector2(0, -30), false)
	add_child(dmg_num)


func _on_hitbox_area_entered(area: Area2D) -> void:
	# Check if this is a hurtbox
	var other_fighter = area.get_parent()
	if other_fighter is FighterController and other_fighter != self:
		var damage = calculate_damage()
		other_fighter.take_damage(damage, self)
		# Disable hitbox after hit
		if hitbox:
			hitbox.monitoring = false
