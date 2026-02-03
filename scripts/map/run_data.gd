extends Resource
class_name RunData
## RunData - Tracks state of current roguelike run

# Fighter data
var fighter_name: String = "Fighter"
var fighter_stats: Resource = null  # FighterStats
var current_hp: float = 100.0
var max_hp: float = 100.0
var gold: int = 50

# Learned moves
var available_moves: Array = []  # Array of Move resources
var equipped_moves: Array = []   # Max 4 equipped

# Map state
var map_nodes: Array = []
var current_node_id: int = 0
var visited_node_ids: Array[int] = []

# Run progress
var battles_won: int = 0
var elites_defeated: int = 0
var current_floor: int = 1  # For multi-floor runs
var is_run_active: bool = false

# Temporary buffs/debuffs
var temp_modifiers: Dictionary = {}


func _init() -> void:
	pass


func start_new_run(stats: Resource, name: String = "Fighter") -> void:
	fighter_name = name
	fighter_stats = stats
	max_hp = stats.get_max_hp()
	current_hp = max_hp
	gold = 50

	available_moves.clear()
	equipped_moves.clear()
	map_nodes.clear()
	visited_node_ids.clear()

	current_node_id = 0
	battles_won = 0
	elites_defeated = 0
	current_floor = 1
	is_run_active = true
	temp_modifiers.clear()

	# Initialize default moves
	_setup_default_moves()


func _setup_default_moves() -> void:
	var MoveLibrary = preload("res://scripts/battle/move_library.gd")

	# Get starter moves
	var starters = MoveLibrary.get_starter_moves()

	# Add basic moves to available pool
	available_moves = starters.duplicate()

	# Equip initial moves (max 4)
	equipped_moves = starters.duplicate()


func learn_move(move: Resource) -> bool:
	# Check if already known
	for m in available_moves:
		if m.move_name == move.move_name:
			return false
	available_moves.append(move)
	return true


func equip_move(move: Resource) -> bool:
	# Max 4 equipped moves
	if equipped_moves.size() >= 4:
		return false

	# Check if already equipped
	for m in equipped_moves:
		if m.move_name == move.move_name:
			return false

	equipped_moves.append(move)
	return true


func unequip_move(move_name: String) -> bool:
	for i in range(equipped_moves.size()):
		if equipped_moves[i].move_name == move_name:
			equipped_moves.remove_at(i)
			return true
	return false


func get_equipped_moves() -> Array:
	return equipped_moves


func get_available_moves() -> Array:
	return available_moves


func heal(amount: float) -> float:
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	return current_hp - old_hp


func take_damage(amount: float) -> void:
	current_hp = max(0, current_hp - amount)


func add_gold(amount: int) -> void:
	gold += amount


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false


func get_hp_ratio() -> float:
	return current_hp / max_hp


func visit_node(node_id: int) -> void:
	if not visited_node_ids.has(node_id):
		visited_node_ids.append(node_id)
	current_node_id = node_id


func is_node_visited(node_id: int) -> bool:
	return visited_node_ids.has(node_id)


func can_move_to_node(node_id: int) -> bool:
	# Find current node
	var current_node = null
	for node in map_nodes:
		if node.id == current_node_id:
			current_node = node
			break

	if current_node == null:
		return false

	# Check if target is connected
	return current_node.connected_to.has(node_id)


func add_stat_point(stat_name: String) -> bool:
	if fighter_stats == null:
		return false

	match stat_name:
		"strength":
			fighter_stats.strength = mini(fighter_stats.strength + 1, 10)
		"agility":
			fighter_stats.agility = mini(fighter_stats.agility + 1, 10)
		"vitality":
			fighter_stats.vitality = mini(fighter_stats.vitality + 1, 10)
			# Update max HP
			var new_max = fighter_stats.get_max_hp()
			var hp_diff = new_max - max_hp
			max_hp = new_max
			current_hp += hp_diff
		"technique":
			fighter_stats.technique = mini(fighter_stats.technique + 1, 10)
		"willpower":
			fighter_stats.willpower = mini(fighter_stats.willpower + 1, 10)
		"intuition":
			fighter_stats.intuition = mini(fighter_stats.intuition + 1, 10)
		_:
			return false

	return true


func record_battle_win(was_elite: bool = false) -> void:
	battles_won += 1
	if was_elite:
		elites_defeated += 1


func end_run(victory: bool) -> Dictionary:
	is_run_active = false
	return {
		"victory": victory,
		"battles_won": battles_won,
		"elites_defeated": elites_defeated,
		"gold_earned": gold,
		"floor_reached": current_floor
	}
