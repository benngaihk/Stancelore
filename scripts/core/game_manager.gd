extends Node
## GameManager - Global state management singleton
## Handles game state, battle state, and provides utility functions

enum GameState {
	MENU,
	BATTLE,
	PAUSED,
	GAME_OVER
}

enum BattleState {
	NOT_STARTED,
	IN_PROGRESS,
	PAUSED,
	ENDED
}

# Current states
var current_game_state: GameState = GameState.MENU
var current_battle_state: BattleState = BattleState.NOT_STARTED

# Battle references
var player_fighter: Node = null
var enemy_fighter: Node = null

# Hit stop system
var _in_hit_stop: bool = false

# Demo settings (persists across scene reloads)
var demo_settings_active: bool = false
var demo_player_stats: Resource = null
var demo_enemy_stats: Resource = null
var demo_player_moves: Array = []
var demo_enemy_moves: Array = []


func _ready() -> void:
	print("[GameManager] Initialized")
	EventBus.hit_stop_requested.connect(_on_hit_stop_requested)


func start_battle(player: Node, enemy: Node) -> void:
	player_fighter = player
	enemy_fighter = enemy
	current_game_state = GameState.BATTLE
	current_battle_state = BattleState.IN_PROGRESS
	EventBus.battle_started.emit()
	print("[GameManager] Battle started")


func end_battle(winner: Node) -> void:
	current_battle_state = BattleState.ENDED
	EventBus.battle_ended.emit(winner)
	print("[GameManager] Battle ended, winner: ", winner.name if winner else "None")


func pause_battle() -> void:
	if current_battle_state == BattleState.IN_PROGRESS:
		current_battle_state = BattleState.PAUSED
		current_game_state = GameState.PAUSED


func resume_battle() -> void:
	if current_battle_state == BattleState.PAUSED:
		current_battle_state = BattleState.IN_PROGRESS
		current_game_state = GameState.BATTLE


func is_battle_active() -> bool:
	return current_battle_state == BattleState.IN_PROGRESS


func _on_hit_stop_requested(duration: float) -> void:
	if _in_hit_stop:
		return
	_in_hit_stop = true
	Engine.time_scale = 0.05  # Near-freeze, not full stop
	# Use a timer that ignores time_scale
	var timer = get_tree().create_timer(duration, true, false, true)  # process_always = true
	await timer.timeout
	Engine.time_scale = 1.0
	_in_hit_stop = false
