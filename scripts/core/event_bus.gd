extends Node
## EventBus - Global signal bus for decoupled communication
## All game events pass through here to avoid tight coupling between systems

# Battle events
signal battle_started
signal battle_ended(winner: Node)
signal round_started(round_number: int)
signal round_ended(round_number: int, winner: Node)

# Fighter events
signal fighter_state_changed(fighter: Node, old_state: int, new_state: int)
signal fighter_attacked(attacker: Node, target: Node)
signal fighter_hit(attacker: Node, target: Node, damage: float)
signal fighter_blocked(defender: Node, attacker: Node)
signal fighter_evaded(evader: Node, attacker: Node)
signal fighter_hp_changed(fighter: Node, old_hp: float, new_hp: float)
signal fighter_defeated(fighter: Node)

# Coach events
signal coach_instruction_given(instruction: String)
signal coach_instruction_cooldown_started(duration: float)
signal coach_instruction_cooldown_ended

# AI events
signal ai_decision_made(fighter: Node, action: String)

# Hit feedback events
signal hit_stop_requested(duration: float)
signal screen_shake_requested(intensity: float, duration: float)


func _ready() -> void:
	print("[EventBus] Initialized")
