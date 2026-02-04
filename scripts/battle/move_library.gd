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


# Get random shop moves (with chance for affixed versions)
static func get_shop_moves(floor_number: int, count: int = 3) -> Array:
	var all_moves = get_basic_moves() + get_skill_moves()
	var result = []

	# Shuffle and pick random moves
	all_moves.shuffle()

	for i in range(min(count, all_moves.size())):
		var base_move = all_moves[i]

		# Chance for affixed version increases with floor
		var affix_chance = 0.1 + floor_number * 0.05  # 10% base + 5% per floor
		affix_chance = min(affix_chance, 0.5)  # Cap at 50%

		if randf() < affix_chance:
			# Create affixed version
			var affix_tier = 1
			if floor_number >= 6:
				affix_tier = 2
			if floor_number >= 10:
				affix_tier = 3
			result.append(MoveClass.create_with_random_affix(base_move, affix_tier))
		else:
			result.append(base_move)

	return result


# Get price for a move
static func get_move_price(move: Resource) -> int:
	var base_price = 0

	# Base price by move type
	match move.move_type:
		MoveClass.MoveType.BASIC:
			base_price = 30
		MoveClass.MoveType.SKILL:
			base_price = 60
		MoveClass.MoveType.ULTIMATE:
			base_price = 120

	# Increase price based on damage
	base_price = int(base_price * move.damage_multiplier)

	# Increase price for affixes
	if move.element_affix != MoveClass.ElementAffix.NONE:
		base_price = int(base_price * 1.4)
	if move.effect_affix != MoveClass.EffectAffix.NONE:
		base_price = int(base_price * 1.3)
	if move.quality_affix != MoveClass.QualityAffix.NONE:
		base_price = int(base_price * 1.25)

	return base_price


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
