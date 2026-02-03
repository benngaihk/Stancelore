extends RefCounted
class_name DecisionTable
## DecisionTable - Stores and retrieves action probabilities based on context

enum Distance {
	CLOSE,   # < 40 pixels
	MID,     # 40-80 pixels
	FAR      # > 80 pixels
}

enum HPState {
	HEALTHY,  # > 60%
	HURT,     # 30-60%
	DANGER    # < 30%
}

enum Action {
	ATTACK,
	DEFEND,
	EVADE,
	COUNTER,
	IDLE
}

# Base probability tables
# Format: {Distance: {HPState: {Action: probability}}}
var base_probabilities: Dictionary = {}


func _init() -> void:
	_setup_base_probabilities()


func _setup_base_probabilities() -> void:
	# CLOSE distance
	base_probabilities[Distance.CLOSE] = {
		HPState.HEALTHY: {
			Action.ATTACK: 0.45,
			Action.DEFEND: 0.20,
			Action.EVADE: 0.15,
			Action.COUNTER: 0.10,
			Action.IDLE: 0.10
		},
		HPState.HURT: {
			Action.ATTACK: 0.35,
			Action.DEFEND: 0.30,
			Action.EVADE: 0.20,
			Action.COUNTER: 0.10,
			Action.IDLE: 0.05
		},
		HPState.DANGER: {
			Action.ATTACK: 0.25,
			Action.DEFEND: 0.35,
			Action.EVADE: 0.25,
			Action.COUNTER: 0.10,
			Action.IDLE: 0.05
		}
	}

	# MID distance
	base_probabilities[Distance.MID] = {
		HPState.HEALTHY: {
			Action.ATTACK: 0.35,
			Action.DEFEND: 0.15,
			Action.EVADE: 0.10,
			Action.COUNTER: 0.15,
			Action.IDLE: 0.25
		},
		HPState.HURT: {
			Action.ATTACK: 0.30,
			Action.DEFEND: 0.25,
			Action.EVADE: 0.15,
			Action.COUNTER: 0.15,
			Action.IDLE: 0.15
		},
		HPState.DANGER: {
			Action.ATTACK: 0.20,
			Action.DEFEND: 0.30,
			Action.EVADE: 0.25,
			Action.COUNTER: 0.15,
			Action.IDLE: 0.10
		}
	}

	# FAR distance
	base_probabilities[Distance.FAR] = {
		HPState.HEALTHY: {
			Action.ATTACK: 0.15,
			Action.DEFEND: 0.10,
			Action.EVADE: 0.05,
			Action.COUNTER: 0.10,
			Action.IDLE: 0.60  # Move closer (IDLE triggers approach)
		},
		HPState.HURT: {
			Action.ATTACK: 0.15,
			Action.DEFEND: 0.15,
			Action.EVADE: 0.10,
			Action.COUNTER: 0.10,
			Action.IDLE: 0.50
		},
		HPState.DANGER: {
			Action.ATTACK: 0.10,
			Action.DEFEND: 0.20,
			Action.EVADE: 0.15,
			Action.COUNTER: 0.15,
			Action.IDLE: 0.40
		}
	}


func get_distance_category(distance: float) -> Distance:
	if distance < 40:
		return Distance.CLOSE
	elif distance < 80:
		return Distance.MID
	else:
		return Distance.FAR


func get_hp_category(hp_ratio: float) -> HPState:
	if hp_ratio > 0.6:
		return HPState.HEALTHY
	elif hp_ratio > 0.3:
		return HPState.HURT
	else:
		return HPState.DANGER


func get_base_probabilities(distance: Distance, hp_state: HPState) -> Dictionary:
	if base_probabilities.has(distance) and base_probabilities[distance].has(hp_state):
		return base_probabilities[distance][hp_state].duplicate()
	# Fallback to default
	return {
		Action.ATTACK: 0.40,
		Action.DEFEND: 0.25,
		Action.EVADE: 0.15,
		Action.COUNTER: 0.10,
		Action.IDLE: 0.10
	}


static func action_to_string(action: Action) -> String:
	match action:
		Action.ATTACK: return "ATTACK"
		Action.DEFEND: return "DEFEND"
		Action.EVADE: return "EVADE"
		Action.COUNTER: return "COUNTER"
		Action.IDLE: return "IDLE"
	return "UNKNOWN"
