extends Node
class_name MoveLibrary
## MoveLibrary - Central repository of all available moves

const MoveClass = preload("res://scripts/battle/move.gd")


# Get all basic moves
static func get_basic_moves() -> Array:
	return [
		MoveClass.create_jab(),
		MoveClass.create_straight(),
		MoveClass.create_hook(),
		MoveClass.create_uppercut(),
		MoveClass.create_body_blow(),
		MoveClass.create_low_kick(),
		MoveClass.create_front_kick(),
		MoveClass.create_knee_strike(),
		MoveClass.create_elbow_strike(),
	]


# Get all skill moves
static func get_skill_moves() -> Array:
	return [
		MoveClass.create_flurry(),
		MoveClass.create_counter_punch(),
		MoveClass.create_roundhouse(),
		MoveClass.create_spinning_backfist(),
		MoveClass.create_gazelle_punch(),
	]


# Get all ultimate moves
static func get_ultimate_moves() -> Array:
	return [
		MoveClass.create_haymaker(),
		MoveClass.create_dempsey_roll(),
	]


# Get starter moves for new run
static func get_starter_moves() -> Array:
	return [
		MoveClass.create_jab(),
		MoveClass.create_straight(),
	]


# Get random learnable move (not in current available list)
static func get_random_learnable_move(current_moves: Array) -> Resource:
	var all_moves = get_basic_moves() + get_skill_moves()
	var current_names = []
	for m in current_moves:
		current_names.append(m.move_name)

	var learnable = []
	for move in all_moves:
		if not current_names.has(move.move_name):
			learnable.append(move)

	if learnable.is_empty():
		return null

	return learnable[randi() % learnable.size()]


# Get move by name
static func get_move_by_name(move_name: String) -> Resource:
	var all_moves = get_basic_moves() + get_skill_moves() + get_ultimate_moves()
	for move in all_moves:
		if move.move_name == move_name:
			return move
	return null


# Get moves suitable for training reward (based on stats)
static func get_training_reward_moves(stats: Resource, count: int = 3) -> Array:
	var all_moves = get_basic_moves() + get_skill_moves()
	var suitable = []

	for move in all_moves:
		var suitability = 1.0

		# Check stat synergy
		if move.combo_starter and stats.technique >= 5:
			suitability += 0.5
		if move.damage_multiplier > 1.3 and stats.strength >= 6:
			suitability += 0.5
		if move.startup_multiplier < 1.0 and stats.agility >= 6:
			suitability += 0.5
		if move.move_type == MoveClass.MoveType.SKILL and stats.intuition >= 5:
			suitability += 0.5

		suitable.append({"move": move, "weight": suitability})

	# Sort by weight and return top moves
	suitable.sort_custom(func(a, b): return a.weight > b.weight)

	var result = []
	for i in range(min(count, suitable.size())):
		result.append(suitable[i].move)

	return result


# Create a specific affixed move (for testing/rewards)
static func create_affixed_move(base_name: String, element: int = 0, effect: int = 0, quality: int = 0) -> Resource:
	var base_move = get_move_by_name(base_name)
	if not base_move:
		return null

	var new_move = base_move.duplicate()
	new_move.base_name = base_move.move_name

	if element > 0:
		new_move.apply_element_affix(element as MoveClass.ElementAffix)
	if effect > 0:
		new_move.apply_effect_affix(effect as MoveClass.EffectAffix)
	if quality > 0:
		new_move.apply_quality_affix(quality as MoveClass.QualityAffix)

	return new_move
