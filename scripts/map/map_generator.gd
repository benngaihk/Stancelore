extends RefCounted
class_name MapGenerator
## MapGenerator - Generates roguelike node maps

const MapNodeScript = preload("res://scripts/map/map_node.gd")

# Map configuration
var num_rows: int = 7  # Total rows including start and boss
var min_nodes_per_row: int = 2
var max_nodes_per_row: int = 4
var min_connections: int = 1
var max_connections: int = 2

# Node type weights by row progress (0.0 = start, 1.0 = boss)
var type_weights: Dictionary = {
	MapNodeScript.NodeType.BATTLE: 45,
	MapNodeScript.NodeType.ELITE: 12,
	MapNodeScript.NodeType.TRAINING: 18,
	MapNodeScript.NodeType.EVENT: 15,
	MapNodeScript.NodeType.REST: 10,
}

var generated_nodes: Array = []
var node_id_counter: int = 0


func generate_map() -> Array:
	generated_nodes.clear()
	node_id_counter = 0

	# Row 0: Starting node
	var start_node = _create_node(0, 0, MapNodeScript.NodeType.BATTLE)
	start_node.is_available = true
	start_node.difficulty = 1
	generated_nodes.append(start_node)

	# Middle rows
	var previous_row_nodes: Array = [start_node]

	for row in range(1, num_rows - 1):
		var row_nodes = _generate_row(row, previous_row_nodes)
		generated_nodes.append_array(row_nodes)
		previous_row_nodes = row_nodes

	# Final row: Boss node
	var boss_node = _create_node(num_rows - 1, max_nodes_per_row / 2, MapNodeScript.NodeType.BOSS)
	boss_node.difficulty = 10

	# Connect all nodes in second-to-last row to boss
	for node in previous_row_nodes:
		node.connected_to.append(boss_node.id)

	generated_nodes.append(boss_node)

	return generated_nodes


func _generate_row(row: int, previous_row: Array) -> Array:
	var row_nodes: Array = []
	var num_nodes = randi_range(min_nodes_per_row, max_nodes_per_row)

	# Calculate spacing
	var spacing = max_nodes_per_row / float(num_nodes + 1)

	for i in range(num_nodes):
		var column = int((i + 1) * spacing)
		var node_type = _pick_node_type(row)
		var node = _create_node(row, column, node_type)
		node.difficulty = _calculate_difficulty(row)
		row_nodes.append(node)

	# Create connections from previous row
	_connect_rows(previous_row, row_nodes)

	return row_nodes


func _create_node(row: int, column: int, type: int) -> Resource:
	var node = MapNodeScript.new()
	node.id = node_id_counter
	node_id_counter += 1
	node.row = row
	node.column = column
	node.node_type = type
	return node


func _pick_node_type(row: int) -> int:
	var progress = float(row) / float(num_rows - 1)

	# Adjust weights based on progress
	var adjusted_weights = type_weights.duplicate()

	# More elites later in the run
	if progress > 0.5:
		adjusted_weights[MapNodeScript.NodeType.ELITE] *= 1.5

	# More training early on
	if progress < 0.4:
		adjusted_weights[MapNodeScript.NodeType.TRAINING] *= 1.3

	# Rest stops more valuable later
	if progress > 0.6:
		adjusted_weights[MapNodeScript.NodeType.REST] *= 1.3

	# Pick weighted random
	var total_weight = 0
	for weight in adjusted_weights.values():
		total_weight += weight

	var roll = randf() * total_weight
	var cumulative = 0.0

	for type in adjusted_weights.keys():
		cumulative += adjusted_weights[type]
		if roll <= cumulative:
			return type

	return MapNodeScript.NodeType.BATTLE


func _calculate_difficulty(row: int) -> int:
	var base_difficulty = 1 + int(row * 1.5)
	var variance = randi_range(-1, 1)
	return clampi(base_difficulty + variance, 1, 10)


func _connect_rows(from_row: Array, to_row: Array) -> void:
	# Ensure every node in to_row has at least one incoming connection
	# and every node in from_row has at least one outgoing connection

	# First, give each from_node at least one connection
	for from_node in from_row:
		var num_connections = randi_range(min_connections, max_connections)
		var available_targets = to_row.duplicate()

		for _i in range(num_connections):
			if available_targets.is_empty():
				break

			# Pick closest node that isn't already connected
			var best_target = null
			var best_distance = 999

			for target in available_targets:
				var distance = abs(target.column - from_node.column)
				if distance < best_distance:
					best_distance = distance
					best_target = target

			if best_target and not from_node.connected_to.has(best_target.id):
				from_node.connected_to.append(best_target.id)
				available_targets.erase(best_target)

	# Ensure every to_node has at least one incoming connection
	for to_node in to_row:
		var has_connection = false
		for from_node in from_row:
			if from_node.connected_to.has(to_node.id):
				has_connection = true
				break

		if not has_connection:
			# Connect from nearest from_node
			var best_from = null
			var best_distance = 999

			for from_node in from_row:
				var distance = abs(from_node.column - to_node.column)
				if distance < best_distance:
					best_distance = distance
					best_from = from_node

			if best_from:
				best_from.connected_to.append(to_node.id)


func get_node_by_id(id: int) -> Resource:
	for node in generated_nodes:
		if node.id == id:
			return node
	return null


func get_nodes_in_row(row: int) -> Array:
	var result: Array = []
	for node in generated_nodes:
		if node.row == row:
			result.append(node)
	return result
