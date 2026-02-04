extends Node
class_name MoveLearner
## MoveLearner - Handles battle-based move acquisition
## Learning methods:
## - 被动领悟 (Passive): Chance to learn moves used against you
## - 碰撞融合 (Fusion): When both fighters use similar moves, chance for affixed version
## - 连招领悟 (Combo): Learn moves after achieving high combos
## - 压力突破 (Pressure): Learn defensive moves when surviving at low HP

const MoveClass = preload("res://scripts/battle/move.gd")
const MoveLibrary = preload("res://scripts/battle/move_library.gd")

# Learning progress tracking
var enemy_moves_seen: Dictionary = {}  # move_name -> times_hit_by
var combo_peak: int = 0
var low_hp_survival_count: int = 0
var simultaneous_attacks: int = 0

# Learning thresholds
const PASSIVE_LEARN_THRESHOLD: int = 3  # Times hit by same move to learn
const COMBO_LEARN_THRESHOLD: int = 5    # Combo count to trigger learning
const LOW_HP_THRESHOLD: float = 0.25    # HP ratio considered "low"
const LOW_HP_SURVIVAL_THRESHOLD: int = 2  # Times surviving at low HP

# Learning chances
const BASE_PASSIVE_LEARN_CHANCE: float = 0.3
const BASE_COMBO_LEARN_CHANCE: float = 0.4
const BASE_PRESSURE_LEARN_CHANCE: float = 0.35
const BASE_FUSION_CHANCE: float = 0.2

# Pending learnable moves (offered after battle)
var pending_moves: Array = []

# Reference to player fighter
var player_fighter: FighterController = null


func _ready() -> void:
	# Connect to battle events
	EventBus.fighter_hit.connect(_on_fighter_hit)
	EventBus.fighter_attacked.connect(_on_fighter_attacked)
	EventBus.fighter_state_changed.connect(_on_fighter_state_changed)


func set_player_fighter(fighter: FighterController) -> void:
	player_fighter = fighter


func _on_fighter_hit(attacker: FighterController, target: FighterController, _damage: float) -> void:
	# Track moves used against player (Passive Learning)
	if target == player_fighter and attacker.current_move:
		var move_name = attacker.current_move.move_name
		var base_name = attacker.current_move.base_name if attacker.current_move.base_name else move_name

		if not enemy_moves_seen.has(base_name):
			enemy_moves_seen[base_name] = 0
		enemy_moves_seen[base_name] += 1

		# Check for passive learning trigger
		if enemy_moves_seen[base_name] >= PASSIVE_LEARN_THRESHOLD:
			_try_passive_learn(attacker.current_move)

	# Track player's combo (Combo Learning)
	if attacker == player_fighter:
		if attacker.combo_count > combo_peak:
			combo_peak = attacker.combo_count

			# Check for combo learning trigger
			if combo_peak >= COMBO_LEARN_THRESHOLD and combo_peak % COMBO_LEARN_THRESHOLD == 0:
				_try_combo_learn(combo_peak)


func _on_fighter_attacked(attacker: FighterController, target: FighterController) -> void:
	# Track simultaneous attacks for Fusion Learning
	if attacker != player_fighter and target == player_fighter:
		# Check if player is also attacking
		if player_fighter.current_state == FighterController.State.ATTACK:
			simultaneous_attacks += 1
			if simultaneous_attacks >= 2:
				_try_fusion_learn(player_fighter.current_move, attacker.current_move)


func _on_fighter_state_changed(fighter: FighterController, _old_state: int, new_state: int) -> void:
	# Track low HP survival (Pressure Learning)
	if fighter == player_fighter:
		if new_state == FighterController.State.HIT:
			if fighter.get_hp_ratio() <= LOW_HP_THRESHOLD:
				low_hp_survival_count += 1

				if low_hp_survival_count >= LOW_HP_SURVIVAL_THRESHOLD:
					_try_pressure_learn()


func _try_passive_learn(enemy_move: Resource) -> void:
	# Don't learn if already known or pending
	var run = RunManager.get_current_run()
	if run == null:
		return

	var base_name = enemy_move.base_name if enemy_move.base_name else enemy_move.move_name

	for m in run.available_moves:
		var check_name = m.base_name if m.base_name else m.move_name
		if check_name == base_name:
			return  # Already know this move

	for m in pending_moves:
		var check_name = m.base_name if m.base_name else m.move_name
		if check_name == base_name:
			return  # Already pending

	# Roll for learning
	if randf() < BASE_PASSIVE_LEARN_CHANCE:
		# Get the base version of the move
		var learnable = MoveLibrary.get_move_by_name(base_name)
		if learnable:
			pending_moves.append({
				"move": learnable,
				"method": "passive",
				"reason": "Observed enemy's " + base_name
			})
			print("[MoveLearner] Passive learned: ", base_name)


func _try_combo_learn(combo_count: int) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if randf() < BASE_COMBO_LEARN_CHANCE:
		# Learn combo-oriented moves
		var combo_moves = [
			MoveClass.create_flurry(),
			MoveClass.create_elbow_strike(),
			MoveClass.create_knee_strike(),
		]

		# Filter out already known moves
		var learnable = []
		for move in combo_moves:
			var known = false
			for m in run.available_moves:
				if m.move_name == move.move_name:
					known = true
					break
			if not known:
				for m in pending_moves:
					if m["move"].move_name == move.move_name:
						known = true
						break
			if not known:
				learnable.append(move)

		if not learnable.is_empty():
			var chosen = learnable[randi() % learnable.size()]
			pending_moves.append({
				"move": chosen,
				"method": "combo",
				"reason": "Achieved %d hit combo!" % combo_count
			})
			print("[MoveLearner] Combo learned: ", chosen.move_name)


func _try_pressure_learn() -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if randf() < BASE_PRESSURE_LEARN_CHANCE:
		# Learn defensive/counter moves
		var pressure_moves = [
			MoveClass.create_counter_punch(),
			MoveClass.create_body_blow(),
			MoveClass.create_gazelle_punch(),
		]

		# Filter out already known moves
		var learnable = []
		for move in pressure_moves:
			var known = false
			for m in run.available_moves:
				if m.move_name == move.move_name:
					known = true
					break
			if not known:
				for m in pending_moves:
					if m["move"].move_name == move.move_name:
						known = true
						break
			if not known:
				learnable.append(move)

		if not learnable.is_empty():
			var chosen = learnable[randi() % learnable.size()]
			pending_moves.append({
				"move": chosen,
				"method": "pressure",
				"reason": "Survived under pressure!"
			})
			print("[MoveLearner] Pressure learned: ", chosen.move_name)


func _try_fusion_learn(player_move: Resource, enemy_move: Resource) -> void:
	if player_move == null or enemy_move == null:
		return

	var run = RunManager.get_current_run()
	if run == null:
		return

	if randf() < BASE_FUSION_CHANCE:
		# Create an affixed version of player's move
		var floor_num = run.visited_nodes.size() if run.visited_nodes else 1
		var affix_tier = clampi(floor_num / 3, 1, 3)

		var fused_move = MoveClass.create_with_random_affix(player_move, affix_tier)

		# Check if similar affixed version already exists
		for m in run.available_moves:
			if m.move_name == fused_move.move_name:
				return
		for m in pending_moves:
			if m["move"].move_name == fused_move.move_name:
				return

		pending_moves.append({
			"move": fused_move,
			"method": "fusion",
			"reason": "Clashed with enemy attack!"
		})
		print("[MoveLearner] Fusion created: ", fused_move.move_name)


func get_pending_moves() -> Array:
	return pending_moves


func clear_pending_moves() -> void:
	pending_moves.clear()


func apply_pending_move(move_data: Dictionary) -> bool:
	var run = RunManager.get_current_run()
	if run == null:
		return false

	var move = move_data["move"]
	if run.learn_move(move):
		pending_moves.erase(move_data)
		return true
	return false


func reset_for_battle() -> void:
	enemy_moves_seen.clear()
	combo_peak = 0
	low_hp_survival_count = 0
	simultaneous_attacks = 0
	# Don't clear pending_moves - they persist until claimed
