extends Node
## RunManager - Manages roguelike run flow, scene transitions, and game state

const MapGeneratorScript = preload("res://scripts/map/map_generator.gd")
const RunDataScript = preload("res://scripts/map/run_data.gd")
const FighterStatsScript = preload("res://scripts/battle/fighter_stats.gd")

# Scene paths
const SCENE_MAIN_MENU = "res://scenes/ui/main_menu.tscn"
const SCENE_CHARACTER_SELECT = "res://scenes/ui/character_select.tscn"
const SCENE_MAP = "res://scenes/map/map_scene.tscn"
const SCENE_BATTLE = "res://scenes/battle/battle_scene.tscn"
const SCENE_EVENT = "res://scenes/ui/event_scene.tscn"
const SCENE_TRAINING = "res://scenes/ui/training_scene.tscn"
const SCENE_REST = "res://scenes/ui/rest_scene.tscn"
const SCENE_VICTORY = "res://scenes/ui/victory_scene.tscn"
const SCENE_DEFEAT = "res://scenes/ui/defeat_scene.tscn"

# Current run state
var current_run: Resource = null  # RunData
var map_generator: RefCounted = null

# Current battle info (for passing to battle scene)
var pending_battle_difficulty: int = 1
var pending_battle_is_elite: bool = false
var pending_battle_is_boss: bool = false

# Battle performance tracking (set by BattleManager)
var last_battle_max_combo: int = 0
var last_battle_hp_ratio: float = 1.0
var last_battle_rewards: Dictionary = {}

# Signals
signal run_started
signal run_ended(result: Dictionary)
signal node_completed(node_id: int)


func _ready() -> void:
	print("[RunManager] Initialized")


func start_new_run(fighter_stats: Resource, fighter_name: String = "Fighter") -> void:
	# Create run data
	current_run = RunDataScript.new()
	current_run.start_new_run(fighter_stats, fighter_name)

	# Generate map
	map_generator = MapGeneratorScript.new()
	current_run.map_nodes = map_generator.generate_map()

	# Set starting node as available
	if current_run.map_nodes.size() > 0:
		current_run.map_nodes[0].is_available = true
		current_run.map_nodes[0].is_current = true

	run_started.emit()
	print("[RunManager] New run started with ", current_run.map_nodes.size(), " nodes")

	# Go to map
	go_to_map()


func go_to_main_menu() -> void:
	_change_scene(SCENE_MAIN_MENU)


func go_to_character_select() -> void:
	_change_scene(SCENE_CHARACTER_SELECT)


func go_to_map() -> void:
	_change_scene(SCENE_MAP)


func enter_node(node_id: int) -> void:
	if current_run == null:
		return

	var node = _get_node_by_id(node_id)
	if node == null:
		return

	# Mark as visited
	current_run.visit_node(node_id)
	node.is_visited = true
	node.is_current = true

	# Update availability of connected nodes
	for connected_id in node.connected_to:
		var connected_node = _get_node_by_id(connected_id)
		if connected_node:
			connected_node.is_available = true

	# Handle node type
	var MapNodeScript = preload("res://scripts/map/map_node.gd")
	match node.node_type:
		MapNodeScript.NodeType.BATTLE:
			_start_battle(node.difficulty, false, false)
		MapNodeScript.NodeType.ELITE:
			_start_battle(node.difficulty, true, false)
		MapNodeScript.NodeType.BOSS:
			_start_battle(node.difficulty, false, true)
		MapNodeScript.NodeType.TRAINING:
			_change_scene(SCENE_TRAINING)
		MapNodeScript.NodeType.EVENT:
			_change_scene(SCENE_EVENT)
		MapNodeScript.NodeType.REST:
			_change_scene(SCENE_REST)


func _start_battle(difficulty: int, is_elite: bool, is_boss: bool) -> void:
	pending_battle_difficulty = difficulty
	pending_battle_is_elite = is_elite
	pending_battle_is_boss = is_boss
	_change_scene(SCENE_BATTLE)


func on_battle_won() -> void:
	if current_run == null:
		return

	current_run.record_battle_win(pending_battle_is_elite)

	# Calculate rewards
	last_battle_rewards = _calculate_battle_rewards()

	# Apply rewards
	current_run.add_gold(last_battle_rewards.gold)

	# Full heal after winning battle
	current_run.current_hp = current_run.max_hp

	# Check for victory (boss defeated)
	if pending_battle_is_boss:
		end_run(true)
	else:
		node_completed.emit(current_run.current_node_id)
		go_to_map()


func _calculate_battle_rewards() -> Dictionary:
	var rewards = {
		"gold": 0,
		"bonus_gold": 0,
		"combo_bonus": 0,
		"hp_bonus": 0,
	}

	# Base gold reward
	var base_gold = 10 + pending_battle_difficulty * 5

	# Elite/Boss multiplier
	if pending_battle_is_elite:
		base_gold = int(base_gold * 2.0)
	if pending_battle_is_boss:
		base_gold = int(base_gold * 3.0)

	rewards.gold = base_gold

	# Combo bonus (10% per 5 combo hits)
	if last_battle_max_combo >= 5:
		var combo_bonus = int(base_gold * (last_battle_max_combo / 5) * 0.1)
		rewards.combo_bonus = combo_bonus
		rewards.bonus_gold += combo_bonus

	# HP bonus (survive with high HP)
	if last_battle_hp_ratio >= 0.8:
		var hp_bonus = int(base_gold * 0.25)
		rewards.hp_bonus = hp_bonus
		rewards.bonus_gold += hp_bonus
	elif last_battle_hp_ratio >= 0.5:
		var hp_bonus = int(base_gold * 0.1)
		rewards.hp_bonus = hp_bonus
		rewards.bonus_gold += hp_bonus

	rewards.gold += rewards.bonus_gold

	return rewards


func get_last_battle_rewards() -> Dictionary:
	return last_battle_rewards


func on_battle_lost() -> void:
	end_run(false)


func on_node_action_completed() -> void:
	# Called when training/event/shop/rest is done
	if current_run:
		node_completed.emit(current_run.current_node_id)
	go_to_map()


func end_run(victory: bool) -> void:
	if current_run == null:
		return

	var result = current_run.end_run(victory)
	run_ended.emit(result)

	if victory:
		_change_scene(SCENE_VICTORY)
	else:
		_change_scene(SCENE_DEFEAT)


func get_current_run() -> Resource:
	return current_run


func get_current_node():
	if current_run == null:
		return null
	return _get_node_by_id(current_run.current_node_id)


func _get_node_by_id(id: int):
	if current_run == null:
		return null
	for node in current_run.map_nodes:
		if node.id == id:
			return node
	return null


func _change_scene(scene_path: String) -> void:
	# Check if scene exists
	if not ResourceLoader.exists(scene_path):
		push_warning("[RunManager] Scene not found: " + scene_path)
		return

	get_tree().change_scene_to_file(scene_path)


# Enemy archetypes for variety
enum EnemyType {
	BALANCED,
	AGGRESSIVE,
	DEFENSIVE,
	SPEEDY,
	HEAVY,
	COUNTER
}

var enemy_names: Dictionary = {
	EnemyType.BALANCED: ["Rookie", "Fighter", "Contender"],
	EnemyType.AGGRESSIVE: ["Berserker", "Slugger", "Bruiser"],
	EnemyType.DEFENSIVE: ["Guard", "Blocker", "Wall"],
	EnemyType.SPEEDY: ["Flash", "Blur", "Swift"],
	EnemyType.HEAVY: ["Giant", "Tank", "Crusher"],
	EnemyType.COUNTER: ["Viper", "Ghost", "Shadow"]
}


# ===== Helper for creating enemy stats based on difficulty =====

func create_enemy_stats(difficulty: int) -> Resource:
	# Pick random enemy type
	var enemy_type = randi() % EnemyType.size()
	return _create_enemy_by_type(enemy_type, difficulty)


func _create_enemy_by_type(type: int, difficulty: int) -> Resource:
	var stats = FighterStatsScript.new()
	var base = 3 + difficulty / 2

	match type:
		EnemyType.BALANCED:
			stats.strength = clampi(base + randi_range(-1, 1), 1, 10)
			stats.agility = clampi(base + randi_range(-1, 1), 1, 10)
			stats.vitality = clampi(base + randi_range(-1, 1), 1, 10)
			stats.technique = clampi(base + randi_range(-1, 1), 1, 10)
			stats.willpower = clampi(base + randi_range(-1, 1), 1, 10)
			stats.intuition = clampi(base + randi_range(-1, 1), 1, 10)
		EnemyType.AGGRESSIVE:
			stats.strength = clampi(base + 2, 1, 10)
			stats.agility = clampi(base + 1, 1, 10)
			stats.vitality = clampi(base - 1, 1, 10)
			stats.technique = clampi(base, 1, 10)
			stats.willpower = clampi(base - 1, 1, 10)
			stats.intuition = clampi(base - 1, 1, 10)
		EnemyType.DEFENSIVE:
			stats.strength = clampi(base - 1, 1, 10)
			stats.agility = clampi(base - 1, 1, 10)
			stats.vitality = clampi(base + 2, 1, 10)
			stats.technique = clampi(base, 1, 10)
			stats.willpower = clampi(base + 2, 1, 10)
			stats.intuition = clampi(base, 1, 10)
		EnemyType.SPEEDY:
			stats.strength = clampi(base - 1, 1, 10)
			stats.agility = clampi(base + 3, 1, 10)
			stats.vitality = clampi(base - 2, 1, 10)
			stats.technique = clampi(base + 1, 1, 10)
			stats.willpower = clampi(base, 1, 10)
			stats.intuition = clampi(base, 1, 10)
		EnemyType.HEAVY:
			stats.strength = clampi(base + 2, 1, 10)
			stats.agility = clampi(base - 2, 1, 10)
			stats.vitality = clampi(base + 3, 1, 10)
			stats.technique = clampi(base - 1, 1, 10)
			stats.willpower = clampi(base + 1, 1, 10)
			stats.intuition = clampi(base - 1, 1, 10)
		EnemyType.COUNTER:
			stats.strength = clampi(base, 1, 10)
			stats.agility = clampi(base + 1, 1, 10)
			stats.vitality = clampi(base, 1, 10)
			stats.technique = clampi(base + 1, 1, 10)
			stats.willpower = clampi(base, 1, 10)
			stats.intuition = clampi(base + 3, 1, 10)

	return stats


func get_random_enemy_name(difficulty: int) -> String:
	var type = randi() % EnemyType.size()
	var names = enemy_names[type]
	var name = names[randi() % names.size()]
	if difficulty >= 7:
		name = "Elite " + name
	elif difficulty >= 4:
		name = "Veteran " + name
	return name


# Get moves for enemy based on type and difficulty
func get_enemy_moves(enemy_type: int, difficulty: int) -> Array:
	var MoveClass = preload("res://scripts/battle/move.gd")
	var moves = []

	# Base moves everyone gets
	moves.append(MoveClass.create_jab())
	moves.append(MoveClass.create_straight())

	# Type-specific moves
	match enemy_type:
		EnemyType.BALANCED:
			moves.append(MoveClass.create_hook())
			if difficulty >= 3:
				moves.append(MoveClass.create_body_blow())
		EnemyType.AGGRESSIVE:
			moves.append(MoveClass.create_hook())
			moves.append(MoveClass.create_uppercut())
			if difficulty >= 4:
				moves.append(MoveClass.create_flurry())
		EnemyType.DEFENSIVE:
			moves.append(MoveClass.create_body_blow())
			if difficulty >= 3:
				moves.append(MoveClass.create_counter_punch())
		EnemyType.SPEEDY:
			moves.append(MoveClass.create_low_kick())
			moves.append(MoveClass.create_front_kick())
			if difficulty >= 4:
				moves.append(MoveClass.create_knee_strike())
		EnemyType.HEAVY:
			moves.append(MoveClass.create_hook())
			moves.append(MoveClass.create_uppercut())
			if difficulty >= 5:
				moves.append(MoveClass.create_haymaker())
		EnemyType.COUNTER:
			moves.append(MoveClass.create_counter_punch())
			moves.append(MoveClass.create_elbow_strike())
			if difficulty >= 4:
				moves.append(MoveClass.create_spinning_backfist())

	return moves


# Current enemy type (set when creating enemy)
var current_enemy_type: int = EnemyType.BALANCED


func create_enemy_with_type(difficulty: int) -> Dictionary:
	# Pick random enemy type
	var enemy_type = randi() % EnemyType.size()
	current_enemy_type = enemy_type

	var stats = _create_enemy_by_type(enemy_type, difficulty)
	var moves = get_enemy_moves(enemy_type, difficulty)
	var name = get_random_enemy_name(difficulty)

	return {
		"stats": stats,
		"moves": moves,
		"name": name,
		"type": enemy_type
	}
