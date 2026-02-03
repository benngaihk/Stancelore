extends Control
## MapScene - Displays the roguelike node map

const MapNodeScript = preload("res://scripts/map/map_node.gd")

# UI References
@onready var map_container: Control = $MapContainer
@onready var info_panel: Panel = $InfoPanel
@onready var info_label: Label = $InfoPanel/InfoLabel
@onready var hp_bar: ProgressBar = $StatusBar/HPBar
@onready var gold_label: Label = $StatusBar/GoldLabel

# Node visuals
var node_buttons: Dictionary = {}  # node_id -> Button
var connection_lines: Array = []

# Layout settings
const NODE_SIZE: Vector2 = Vector2(24, 24)
const ROW_HEIGHT: float = 28.0
const MAP_MARGIN: Vector2 = Vector2(40, 30)


func _ready() -> void:
	_setup_map()
	_update_status()


func _setup_map() -> void:
	var run = RunManager.get_current_run()
	if run == null or run.map_nodes.is_empty():
		push_warning("No map data available")
		return

	# Clear existing
	for child in map_container.get_children():
		child.queue_free()
	node_buttons.clear()
	connection_lines.clear()

	# Calculate layout
	var map_width = map_container.size.x - MAP_MARGIN.x * 2
	var map_height = map_container.size.y - MAP_MARGIN.y * 2

	# Group nodes by row
	var rows: Dictionary = {}
	var max_row = 0
	for node in run.map_nodes:
		if not rows.has(node.row):
			rows[node.row] = []
		rows[node.row].append(node)
		max_row = max(max_row, node.row)

	# Create node buttons
	for row_idx in rows.keys():
		var row_nodes = rows[row_idx]
		var y_pos = MAP_MARGIN.y + (row_idx * map_height / max(max_row, 1))

		for i in range(row_nodes.size()):
			var node = row_nodes[i]
			var x_pos = MAP_MARGIN.x + ((i + 1) * map_width / (row_nodes.size() + 1))

			var btn = _create_node_button(node, Vector2(x_pos, y_pos))
			map_container.add_child(btn)
			node_buttons[node.id] = btn

	# Draw connections (using Line2D)
	for node in run.map_nodes:
		for connected_id in node.connected_to:
			if node_buttons.has(node.id) and node_buttons.has(connected_id):
				var line = _create_connection_line(
					node_buttons[node.id].position + NODE_SIZE / 2,
					node_buttons[connected_id].position + NODE_SIZE / 2
				)
				map_container.add_child(line)
				# Move line behind buttons
				map_container.move_child(line, 0)


func _create_node_button(node: Resource, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = NODE_SIZE
	btn.size = NODE_SIZE
	btn.position = pos - NODE_SIZE / 2

	# Style based on state
	btn.text = node.get_icon_char()

	if node.is_current:
		btn.modulate = Color.WHITE
		btn.add_theme_color_override("font_color", Color.WHITE)
	elif node.is_visited:
		btn.modulate = Color(0.5, 0.5, 0.5)
		btn.disabled = true
	elif node.is_available:
		btn.modulate = node.get_type_color()
	else:
		btn.modulate = Color(0.3, 0.3, 0.3)
		btn.disabled = true

	# Connect signal
	btn.pressed.connect(_on_node_pressed.bind(node.id))
	btn.mouse_entered.connect(_on_node_hover.bind(node))
	btn.mouse_exited.connect(_on_node_unhover)

	return btn


func _create_connection_line(from: Vector2, to: Vector2) -> Line2D:
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = Color(0.4, 0.4, 0.4, 0.8)
	return line


func _on_node_pressed(node_id: int) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	var node = null
	for n in run.map_nodes:
		if n.id == node_id:
			node = n
			break

	if node == null:
		return

	# Check if we can move there
	if not node.is_available or node.is_visited:
		return

	# Enter the node
	RunManager.enter_node(node_id)


func _on_node_hover(node: Resource) -> void:
	info_panel.visible = true
	var info_text = node.get_type_name()
	info_text += "\nDifficulty: " + str(node.difficulty)

	match node.node_type:
		MapNodeScript.NodeType.BATTLE:
			info_text += "\nFight an opponent"
		MapNodeScript.NodeType.ELITE:
			info_text += "\nStrong enemy, better rewards"
		MapNodeScript.NodeType.TRAINING:
			info_text += "\nUpgrade a stat"
		MapNodeScript.NodeType.EVENT:
			info_text += "\nRandom event"
		MapNodeScript.NodeType.SHOP:
			info_text += "\nBuy items"
		MapNodeScript.NodeType.REST:
			info_text += "\nRecover HP"
		MapNodeScript.NodeType.BOSS:
			info_text += "\nDefeat to win!"

	info_label.text = info_text


func _on_node_unhover() -> void:
	info_panel.visible = false


func _update_status() -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	hp_bar.max_value = run.max_hp
	hp_bar.value = run.current_hp
	gold_label.text = "Gold: " + str(run.gold)
