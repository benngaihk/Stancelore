extends RefCounted
class_name VerletPhysics
## VerletPhysics - Simple Verlet integration for hair and cloth simulation

# A point in the Verlet simulation
class VerletPoint:
	var position: Vector2
	var old_position: Vector2
	var acceleration: Vector2 = Vector2.ZERO
	var is_pinned: bool = false
	var pin_target: Vector2 = Vector2.ZERO  # If pinned, follow this position
	var mass: float = 1.0
	var damping: float = 0.98  # Air resistance

	func _init(pos: Vector2, pinned: bool = false) -> void:
		position = pos
		old_position = pos
		is_pinned = pinned
		pin_target = pos

	func update(delta: float, gravity: Vector2) -> void:
		if is_pinned:
			position = pin_target
			old_position = position
			return

		# Verlet integration
		var velocity = (position - old_position) * damping
		old_position = position
		position += velocity + (acceleration + gravity) * delta * delta
		acceleration = Vector2.ZERO

	func apply_force(force: Vector2) -> void:
		acceleration += force / mass


# A constraint between two points (keeps them at fixed distance)
class DistanceConstraint:
	var point_a: VerletPoint
	var point_b: VerletPoint
	var rest_length: float
	var stiffness: float = 1.0  # 0-1, how rigid the constraint is

	func _init(a: VerletPoint, b: VerletPoint, stiff: float = 1.0) -> void:
		point_a = a
		point_b = b
		rest_length = a.position.distance_to(b.position)
		stiffness = stiff

	func satisfy() -> void:
		var delta = point_b.position - point_a.position
		var current_length = delta.length()
		if current_length == 0:
			return

		var difference = (current_length - rest_length) / current_length
		var correction = delta * difference * 0.5 * stiffness

		if not point_a.is_pinned:
			point_a.position += correction
		if not point_b.is_pinned:
			point_b.position -= correction


# ===== Hair Chain =====
# A chain of points for simulating hair strands
class HairChain:
	var points: Array[VerletPoint] = []
	var constraints: Array[DistanceConstraint] = []
	var segment_length: float = 3.0
	var num_segments: int = 4
	var gravity: Vector2 = Vector2(0, 150)
	var wind_strength: float = 20.0

	func _init(start_pos: Vector2, segments: int, seg_length: float) -> void:
		num_segments = segments
		segment_length = seg_length

		# Create points along the chain
		for i in range(segments + 1):
			var pos = start_pos + Vector2(0, i * segment_length)
			var point = VerletPoint.new(pos, i == 0)  # First point is pinned
			point.damping = 0.95
			points.append(point)

		# Create distance constraints
		for i in range(segments):
			var constraint = DistanceConstraint.new(points[i], points[i + 1], 0.8)
			constraints.append(constraint)

	func update(delta: float, anchor_pos: Vector2, velocity: Vector2 = Vector2.ZERO) -> void:
		# Update pin position
		if points.size() > 0:
			points[0].pin_target = anchor_pos

		# Apply wind based on movement
		var wind = Vector2(-velocity.x * 0.5, 0) + Vector2(sin(Time.get_ticks_msec() * 0.003) * wind_strength, 0)

		# Update all points
		for point in points:
			point.apply_force(wind)
			point.update(delta, gravity)

		# Satisfy constraints multiple times for stability
		for _iteration in range(3):
			for constraint in constraints:
				constraint.satisfy()

	func get_positions() -> Array[Vector2]:
		var positions: Array[Vector2] = []
		for point in points:
			positions.append(point.position)
		return positions


# ===== Cloth Mesh =====
# A grid of points for simulating cloth (like a cape or loose clothing)
class ClothMesh:
	var points: Array = []  # 2D array of VerletPoints
	var constraints: Array[DistanceConstraint] = []
	var width: int = 4
	var height: int = 4
	var spacing: float = 3.0
	var gravity: Vector2 = Vector2(0, 100)

	func _init(top_left: Vector2, w: int, h: int, space: float) -> void:
		width = w
		height = h
		spacing = space

		# Create grid of points
		for y in range(height):
			var row: Array[VerletPoint] = []
			for x in range(width):
				var pos = top_left + Vector2(x * spacing, y * spacing)
				var pinned = (y == 0)  # Pin top row
				var point = VerletPoint.new(pos, pinned)
				point.damping = 0.96
				row.append(point)
			points.append(row)

		# Create horizontal constraints
		for y in range(height):
			for x in range(width - 1):
				constraints.append(DistanceConstraint.new(points[y][x], points[y][x + 1], 0.9))

		# Create vertical constraints
		for y in range(height - 1):
			for x in range(width):
				constraints.append(DistanceConstraint.new(points[y][x], points[y + 1][x], 0.9))

		# Create diagonal constraints for stability
		for y in range(height - 1):
			for x in range(width - 1):
				constraints.append(DistanceConstraint.new(points[y][x], points[y + 1][x + 1], 0.5))
				constraints.append(DistanceConstraint.new(points[y][x + 1], points[y + 1][x], 0.5))

	func update(delta: float, anchor_positions: Array[Vector2], velocity: Vector2 = Vector2.ZERO) -> void:
		# Update pin positions (top row)
		for i in range(min(anchor_positions.size(), width)):
			points[0][i].pin_target = anchor_positions[i]

		# Apply wind
		var wind = Vector2(-velocity.x * 0.3, 0)

		# Update all points
		for row in points:
			for point in row:
				point.apply_force(wind)
				point.update(delta, gravity)

		# Satisfy constraints
		for _iteration in range(4):
			for constraint in constraints:
				constraint.satisfy()

	func get_point(x: int, y: int) -> VerletPoint:
		if y >= 0 and y < height and x >= 0 and x < width:
			return points[y][x]
		return null


# ===== Ragdoll Body =====
# A collection of points and constraints representing a body
class RagdollBody:
	var head: VerletPoint
	var neck: VerletPoint
	var hip: VerletPoint
	var left_shoulder: VerletPoint
	var right_shoulder: VerletPoint
	var left_elbow: VerletPoint
	var right_elbow: VerletPoint
	var left_hand: VerletPoint
	var right_hand: VerletPoint
	var left_hip: VerletPoint
	var right_hip: VerletPoint
	var left_knee: VerletPoint
	var right_knee: VerletPoint
	var left_foot: VerletPoint
	var right_foot: VerletPoint

	var all_points: Array[VerletPoint] = []
	var constraints: Array[DistanceConstraint] = []
	var gravity: Vector2 = Vector2(0, 400)
	var ground_y: float = 0.0
	var is_active: bool = false

	func _init() -> void:
		pass

	func initialize_from_skeleton(skeleton_data: Dictionary, ground: float) -> void:
		ground_y = ground

		# Create points from skeleton positions
		head = VerletPoint.new(skeleton_data.get("head", Vector2.ZERO))
		neck = VerletPoint.new(skeleton_data.get("neck", Vector2.ZERO))
		hip = VerletPoint.new(skeleton_data.get("hip", Vector2.ZERO))
		left_shoulder = VerletPoint.new(skeleton_data.get("left_shoulder", Vector2.ZERO))
		right_shoulder = VerletPoint.new(skeleton_data.get("right_shoulder", Vector2.ZERO))
		left_elbow = VerletPoint.new(skeleton_data.get("left_elbow", Vector2.ZERO))
		right_elbow = VerletPoint.new(skeleton_data.get("right_elbow", Vector2.ZERO))
		left_hand = VerletPoint.new(skeleton_data.get("left_hand", Vector2.ZERO))
		right_hand = VerletPoint.new(skeleton_data.get("right_hand", Vector2.ZERO))
		left_hip = VerletPoint.new(skeleton_data.get("left_hip", Vector2.ZERO))
		right_hip = VerletPoint.new(skeleton_data.get("right_hip", Vector2.ZERO))
		left_knee = VerletPoint.new(skeleton_data.get("left_knee", Vector2.ZERO))
		right_knee = VerletPoint.new(skeleton_data.get("right_knee", Vector2.ZERO))
		left_foot = VerletPoint.new(skeleton_data.get("left_foot", Vector2.ZERO))
		right_foot = VerletPoint.new(skeleton_data.get("right_foot", Vector2.ZERO))

		# Set mass (head heavier, extremities lighter)
		head.mass = 1.5
		neck.mass = 1.0
		hip.mass = 2.0
		left_hand.mass = 0.5
		right_hand.mass = 0.5
		left_foot.mass = 0.8
		right_foot.mass = 0.8

		# Collect all points
		all_points = [head, neck, hip, left_shoulder, right_shoulder,
					  left_elbow, right_elbow, left_hand, right_hand,
					  left_hip, right_hip, left_knee, right_knee,
					  left_foot, right_foot]

		# Set damping
		for point in all_points:
			point.damping = 0.92

		# Create bone constraints (rigid)
		constraints.append(DistanceConstraint.new(head, neck, 1.0))
		constraints.append(DistanceConstraint.new(neck, hip, 1.0))
		constraints.append(DistanceConstraint.new(neck, left_shoulder, 1.0))
		constraints.append(DistanceConstraint.new(neck, right_shoulder, 1.0))
		constraints.append(DistanceConstraint.new(left_shoulder, left_elbow, 1.0))
		constraints.append(DistanceConstraint.new(left_elbow, left_hand, 1.0))
		constraints.append(DistanceConstraint.new(right_shoulder, right_elbow, 1.0))
		constraints.append(DistanceConstraint.new(right_elbow, right_hand, 1.0))
		constraints.append(DistanceConstraint.new(hip, left_hip, 1.0))
		constraints.append(DistanceConstraint.new(hip, right_hip, 1.0))
		constraints.append(DistanceConstraint.new(left_hip, left_knee, 1.0))
		constraints.append(DistanceConstraint.new(left_knee, left_foot, 1.0))
		constraints.append(DistanceConstraint.new(right_hip, right_knee, 1.0))
		constraints.append(DistanceConstraint.new(right_knee, right_foot, 1.0))

		# Cross constraints for stability
		constraints.append(DistanceConstraint.new(left_shoulder, right_shoulder, 0.8))
		constraints.append(DistanceConstraint.new(left_hip, right_hip, 0.8))
		constraints.append(DistanceConstraint.new(neck, left_hip, 0.5))
		constraints.append(DistanceConstraint.new(neck, right_hip, 0.5))

	func activate(impact_force: Vector2 = Vector2.ZERO) -> void:
		is_active = true
		# Apply initial impact
		for point in all_points:
			point.apply_force(impact_force * (1.0 / point.mass))

	func update(delta: float) -> void:
		if not is_active:
			return

		# Update all points
		for point in all_points:
			point.update(delta, gravity)

			# Ground collision
			if point.position.y > ground_y:
				point.position.y = ground_y
				point.old_position.y = point.position.y + (point.position.y - point.old_position.y) * 0.3

		# Satisfy constraints
		for _iteration in range(5):
			for constraint in constraints:
				constraint.satisfy()

			# Re-enforce ground collision
			for point in all_points:
				if point.position.y > ground_y:
					point.position.y = ground_y

	func get_skeleton_data() -> Dictionary:
		return {
			"head": head.position,
			"neck": neck.position,
			"hip": hip.position,
			"left_shoulder": left_shoulder.position,
			"right_shoulder": right_shoulder.position,
			"left_elbow": left_elbow.position,
			"right_elbow": right_elbow.position,
			"left_hand": left_hand.position,
			"right_hand": right_hand.position,
			"left_hip": left_hip.position,
			"right_hip": right_hip.position,
			"left_knee": left_knee.position,
			"right_knee": right_knee.position,
			"left_foot": left_foot.position,
			"right_foot": right_foot.position
		}
