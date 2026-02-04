extends Node
class_name AIBrain
## AIBrain - Handles AI decision making for fighters
## Perception -> Decision Table -> Modifiers -> Normalize -> Random Select

# Decision timing
@export var decision_interval: float = 0.4
var decision_timer: float = 0.0

# References
var fighter: FighterController = null
var decision_table: DecisionTable = null

# Move selection
var equipped_moves: Array = []
var move_cooldowns: Dictionary = {}  # move_name -> remaining cooldown

# Coach instruction modifier
var coach_modifiers: Dictionary = {
	DecisionTable.Action.ATTACK: 1.0,
	DecisionTable.Action.DEFEND: 1.0,
	DecisionTable.Action.EVADE: 1.0,
	DecisionTable.Action.COUNTER: 1.0,
	DecisionTable.Action.IDLE: 1.0
}


func _ready() -> void:
	fighter = get_parent() as FighterController
	decision_table = DecisionTable.new()

	# Connect to coach instructions
	EventBus.coach_instruction_given.connect(_on_coach_instruction)

	# Initialize moves
	if fighter.is_player_controlled:
		_load_moves_from_run()
	else:
		_setup_enemy_moves()


func _load_moves_from_run() -> void:
	var run = RunManager.get_current_run()
	if run and run.equipped_moves.size() > 0:
		equipped_moves = run.equipped_moves.duplicate()
	else:
		# Default moves if no run data
		var MoveClass = preload("res://scripts/battle/move.gd")
		equipped_moves = [
			MoveClass.create_jab(),
			MoveClass.create_straight(),
		]


func set_equipped_moves(moves: Array) -> void:
	equipped_moves = moves.duplicate()
	move_cooldowns.clear()


func _setup_enemy_moves() -> void:
	# Give enemy a basic set of moves
	var MoveClass = preload("res://scripts/battle/move.gd")
	equipped_moves = [
		MoveClass.create_jab(),
		MoveClass.create_straight(),
		MoveClass.create_hook(),
	]


func _process(delta: float) -> void:
	if not GameManager.is_battle_active():
		return

	# Update move cooldowns
	_update_cooldowns(delta)

	if not fighter or not fighter.can_act():
		return

	decision_timer -= delta
	if decision_timer <= 0:
		decision_timer = decision_interval + randf_range(-0.1, 0.1)  # Add variance
		make_decision()


func _update_cooldowns(delta: float) -> void:
	var to_remove = []
	for move_name in move_cooldowns.keys():
		move_cooldowns[move_name] -= delta
		if move_cooldowns[move_name] <= 0:
			to_remove.append(move_name)
	for move_name in to_remove:
		move_cooldowns.erase(move_name)


func make_decision() -> void:
	if not fighter.target:
		return

	# 1. Perception
	var distance = fighter.get_distance_to_target()
	var hp_ratio = fighter.get_hp_ratio()
	var stamina_ratio = fighter.get_stamina_ratio()

	var dist_cat = decision_table.get_distance_category(distance)
	var hp_cat = decision_table.get_hp_category(hp_ratio)

	# 2. Get base probabilities
	var probs = decision_table.get_base_probabilities(dist_cat, hp_cat)

	# 3. Apply stats modifiers (from FighterStats)
	probs = _apply_stats_modifiers(probs)

	# 4. Apply coach modifiers
	probs = _apply_coach_modifiers(probs)

	# 5. Apply stamina consideration
	probs = _apply_stamina_modifiers(probs, stamina_ratio)

	# 6. Normalize
	probs = _normalize_probabilities(probs)

	# 7. Random select
	var action = _weighted_random_select(probs)

	# 8. Execute action
	_execute_action(action, distance)

	EventBus.ai_decision_made.emit(fighter, DecisionTable.action_to_string(action))


func _apply_stats_modifiers(probs: Dictionary) -> Dictionary:
	if not fighter.stats:
		return probs

	var modified = probs.duplicate()
	modified[DecisionTable.Action.ATTACK] *= fighter.stats.get_ai_attack_modifier()
	modified[DecisionTable.Action.DEFEND] *= fighter.stats.get_ai_defend_modifier()
	modified[DecisionTable.Action.EVADE] *= fighter.stats.get_ai_evade_modifier()
	modified[DecisionTable.Action.COUNTER] *= fighter.stats.get_ai_counter_modifier()
	return modified


func _apply_stamina_modifiers(probs: Dictionary, stamina_ratio: float) -> Dictionary:
	var modified = probs.duplicate()

	# Low stamina = more defensive
	if stamina_ratio < 0.3:
		modified[DecisionTable.Action.ATTACK] *= 0.5
		modified[DecisionTable.Action.EVADE] *= 0.7
		modified[DecisionTable.Action.DEFEND] *= 1.5
		modified[DecisionTable.Action.IDLE] *= 2.0  # Rest to recover stamina

	return modified


func _apply_coach_modifiers(probs: Dictionary) -> Dictionary:
	var modified = probs.duplicate()
	for action in modified.keys():
		if coach_modifiers.has(action):
			modified[action] *= coach_modifiers[action]
	return modified


func _normalize_probabilities(probs: Dictionary) -> Dictionary:
	var total = 0.0
	for prob in probs.values():
		total += prob

	if total <= 0:
		return probs

	var normalized = {}
	for action in probs.keys():
		normalized[action] = probs[action] / total

	return normalized


func _weighted_random_select(probs: Dictionary) -> DecisionTable.Action:
	var rand = randf()
	var cumulative = 0.0

	for action in probs.keys():
		cumulative += probs[action]
		if rand <= cumulative:
			return action

	# Fallback
	return DecisionTable.Action.IDLE


func _execute_action(action: DecisionTable.Action, distance: float) -> void:
	# Check stance from coach modifiers
	var is_evasive = coach_modifiers.get(DecisionTable.Action.EVADE, 1.0) > 2.5
	var is_pressure = coach_modifiers.get(DecisionTable.Action.IDLE, 1.0) < 0.3
	var is_counter = coach_modifiers.get(DecisionTable.Action.COUNTER, 1.0) > 3.0
	var is_defensive = coach_modifiers.get(DecisionTable.Action.DEFEND, 1.0) > 2.0

	match action:
		DecisionTable.Action.ATTACK:
			if distance < fighter.attack_range:
				var move = _select_best_move(distance)
				fighter.do_attack(move)
				# Apply cooldown if move has one
				if move and move.cooldown > 0:
					move_cooldowns[move.move_name] = move.cooldown
			else:
				fighter.do_walk()  # Move closer first
		DecisionTable.Action.DEFEND:
			fighter.do_defend()
		DecisionTable.Action.EVADE:
			fighter.do_evade()  # Evade moves backward
		DecisionTable.Action.COUNTER:
			# Counter stance: defend but prepare to attack immediately
			fighter.do_defend()
			# Note: Counter attack logic handled in fighter_controller when hit while defending
		DecisionTable.Action.IDLE:
			if is_evasive:
				# Evasive: Keep distance, back away when close
				if distance < 60:
					fighter.do_evade()
				# Stay away
			elif is_pressure:
				# Pressure: Always move toward enemy
				if distance > 30:
					fighter.do_walk()
			elif is_counter:
				# Counter stance: Stay at mid range, ready to react
				if distance > 60:
					fighter.do_walk()
				elif distance < 35:
					fighter.do_evade()
			elif is_defensive and distance < 60:
				# Defensive: Back away when close
				fighter.do_evade()
			elif distance > 50:
				fighter.do_walk()


func _select_best_move(distance: float) -> Resource:
	if equipped_moves.is_empty():
		return null

	var available = []

	for move in equipped_moves:
		# Skip if on cooldown
		if move_cooldowns.has(move.move_name):
			continue
		# Check if can use (stamina, combo requirements)
		if move.can_use(fighter):
			available.append(move)

	if available.is_empty():
		# Fall back to any usable basic move
		for move in equipped_moves:
			if move.move_type == preload("res://scripts/battle/move.gd").MoveType.BASIC:
				if fighter.has_stamina(move.stamina_cost):
					return move
		return null

	# Weight selection based on situation
	var weights = []
	for move in available:
		var weight = 1.0

		# Prefer combo starters at the beginning
		if fighter.combo_count == 0 and move.combo_starter:
			weight *= 1.5

		# Prefer combo enders when combo is high
		if fighter.combo_count >= 3 and move.combo_ender:
			weight *= 2.0

		# Prefer high damage moves when enemy HP is low
		if fighter.target and fighter.target.get_hp_ratio() < 0.3:
			weight *= move.damage_multiplier

		# Prefer fast moves when low on stamina
		if fighter.get_stamina_ratio() < 0.4:
			weight *= (1.0 / move.stamina_cost) * 10

		# Skills and ultimates are less frequent
		if move.move_type == preload("res://scripts/battle/move.gd").MoveType.SKILL:
			weight *= 0.6
		elif move.move_type == preload("res://scripts/battle/move.gd").MoveType.ULTIMATE:
			weight *= 0.3

		weights.append(weight)

	# Weighted random selection
	var total = 0.0
	for w in weights:
		total += w

	var rand = randf() * total
	var cumulative = 0.0
	for i in range(available.size()):
		cumulative += weights[i]
		if rand <= cumulative:
			return available[i]

	return available[0]


func _on_coach_instruction(instruction: String) -> void:
	# Only apply to player's fighter
	if not fighter.is_player_controlled:
		return

	match instruction:
		"aggressive":
			# 猛攻: All-out attack, high risk high reward
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 2.5,
				DecisionTable.Action.DEFEND: 0.2,
				DecisionTable.Action.EVADE: 0.3,
				DecisionTable.Action.COUNTER: 1.5,
				DecisionTable.Action.IDLE: 0.3
			}
		"balanced":
			# 均衡: No modifiers, base behavior
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 1.0,
				DecisionTable.Action.DEFEND: 1.0,
				DecisionTable.Action.EVADE: 1.0,
				DecisionTable.Action.COUNTER: 1.0,
				DecisionTable.Action.IDLE: 1.0
			}
		"defensive":
			# 防守: Focus on blocking, minimal attacks
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 0.2,
				DecisionTable.Action.DEFEND: 2.5,
				DecisionTable.Action.EVADE: 2.0,
				DecisionTable.Action.COUNTER: 0.5,
				DecisionTable.Action.IDLE: 2.0
			}
		"evasive":
			# 回避: Focus on dodging, keep distance
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 0.3,
				DecisionTable.Action.DEFEND: 0.5,
				DecisionTable.Action.EVADE: 3.0,
				DecisionTable.Action.COUNTER: 0.3,
				DecisionTable.Action.IDLE: 1.5
			}
		"counter":
			# 反击: Wait for enemy attack, then counter
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 0.5,
				DecisionTable.Action.DEFEND: 1.8,
				DecisionTable.Action.EVADE: 1.0,
				DecisionTable.Action.COUNTER: 3.5,
				DecisionTable.Action.IDLE: 1.2
			}
		"pressure":
			# 压制: Stay close, harass with quick attacks
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 1.8,
				DecisionTable.Action.DEFEND: 0.8,
				DecisionTable.Action.EVADE: 0.5,
				DecisionTable.Action.COUNTER: 1.0,
				DecisionTable.Action.IDLE: 0.2
			}

	print("[AIBrain] Coach instruction applied: ", instruction)
