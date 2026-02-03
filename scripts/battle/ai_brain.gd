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


func _process(delta: float) -> void:
	if not GameManager.is_battle_active():
		return

	if not fighter or not fighter.can_act():
		return

	decision_timer -= delta
	if decision_timer <= 0:
		decision_timer = decision_interval + randf_range(-0.1, 0.1)  # Add variance
		make_decision()


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
	# Check if in defensive stance (high evade modifier means defensive)
	var is_defensive = coach_modifiers.get(DecisionTable.Action.EVADE, 1.0) > 1.2

	match action:
		DecisionTable.Action.ATTACK:
			if distance < fighter.attack_range:
				fighter.do_attack()
			else:
				fighter.do_walk()  # Move closer first
		DecisionTable.Action.DEFEND:
			fighter.do_defend()
		DecisionTable.Action.EVADE:
			fighter.do_evade()  # Evade moves backward
		DecisionTable.Action.COUNTER:
			fighter.do_defend()
		DecisionTable.Action.IDLE:
			if is_defensive and distance < 60:
				# In defensive mode at close range, back away
				fighter.do_evade()
			elif distance > 50:
				fighter.do_walk()


func _on_coach_instruction(instruction: String) -> void:
	# Only apply to player's fighter
	if not fighter.is_player_controlled:
		return

	match instruction:
		"aggressive":
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 2.5,
				DecisionTable.Action.DEFEND: 0.2,
				DecisionTable.Action.EVADE: 0.3,
				DecisionTable.Action.COUNTER: 1.5,
				DecisionTable.Action.IDLE: 0.3
			}
		"balanced":
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 1.0,
				DecisionTable.Action.DEFEND: 1.0,
				DecisionTable.Action.EVADE: 1.0,
				DecisionTable.Action.COUNTER: 1.0,
				DecisionTable.Action.IDLE: 1.0
			}
		"defensive":
			coach_modifiers = {
				DecisionTable.Action.ATTACK: 0.2,
				DecisionTable.Action.DEFEND: 2.5,
				DecisionTable.Action.EVADE: 2.0,
				DecisionTable.Action.COUNTER: 0.5,
				DecisionTable.Action.IDLE: 2.0
			}

	print("[AIBrain] Coach instruction applied: ", instruction)
