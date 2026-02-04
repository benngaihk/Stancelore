extends Resource
class_name MapNode
## MapNode - Represents a single node on the roguelike map

enum NodeType {
	BATTLE,     # Normal fight
	ELITE,      # Harder fight, better rewards
	TRAINING,   # Upgrade stats
	EVENT,      # Random event
	REST,       # Heal HP
	BOSS        # Boss fight
}

# Node identification
@export var id: int = 0
@export var row: int = 0  # Vertical position (0 = start, higher = further)
@export var column: int = 0  # Horizontal position

# Node properties
@export var node_type: NodeType = NodeType.BATTLE
@export var is_visited: bool = false
@export var is_available: bool = false  # Can player move here?
@export var is_current: bool = false

# Connections
@export var connected_to: Array[int] = []  # IDs of nodes this connects to

# Node-specific data
@export var difficulty: int = 1  # 1-10 scale
@export var rewards: Dictionary = {}


func _init() -> void:
	pass


func get_type_name() -> String:
	match node_type:
		NodeType.BATTLE: return "Battle"
		NodeType.ELITE: return "Elite"
		NodeType.TRAINING: return "Training"
		NodeType.EVENT: return "Event"
		NodeType.REST: return "Rest"
		NodeType.BOSS: return "Boss"
	return "Unknown"


func get_type_color() -> Color:
	match node_type:
		NodeType.BATTLE: return Color(0.8, 0.3, 0.3)  # Red
		NodeType.ELITE: return Color(0.9, 0.6, 0.1)   # Orange
		NodeType.TRAINING: return Color(0.3, 0.7, 0.3) # Green
		NodeType.EVENT: return Color(0.6, 0.4, 0.8)   # Purple
		NodeType.REST: return Color(0.3, 0.6, 0.9)    # Blue
		NodeType.BOSS: return Color(0.9, 0.2, 0.5)    # Magenta
	return Color.WHITE


func get_icon_char() -> String:
	match node_type:
		NodeType.BATTLE: return "B"
		NodeType.ELITE: return "E"
		NodeType.TRAINING: return "T"
		NodeType.EVENT: return "?"
		NodeType.REST: return "R"
		NodeType.BOSS: return "X"
	return "?"
