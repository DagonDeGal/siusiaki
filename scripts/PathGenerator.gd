extends Node

class_name PathGenerator

enum Direction { UP, DOWN, LEFT, RIGHT }

static func generate_maze_path(start_pos: Vector2, end_pos: Vector2, grid_size: int, complexity: int = 3) -> Array:
	var path = []
	var current = start_pos
	var target = end_pos

	# Always move towards target with some randomness
	while current.distance_to(target) > grid_size:
		var direction_to_target = (target - current).normalized()
		var next_pos = current

		# Decide whether to move towards target or add complexity
		if randf() < 0.7:  # 70% chance to move towards target
			if abs(direction_to_target.x) > abs(direction_to_target.y):
				# Move horizontally
				if direction_to_target.x > 0:
					next_pos.x += grid_size
				else:
					next_pos.x -= grid_size
			else:
				# Move vertically
				if direction_to_target.y > 0:
					next_pos.y += grid_size
				else:
					next_pos.y -= grid_size
		else:
			# Add some randomness for complexity
			var random_directions = [
				Vector2(grid_size, 0), Vector2(-grid_size, 0),
				Vector2(0, grid_size), Vector2(0, -grid_size)
			]
			var random_dir = random_directions[randi() % random_directions.size()]
			next_pos = current + random_dir

		# Make sure we don't go off screen bounds
		next_pos = BoundsHelper.clamp_to_screen(next_pos)

		path.append(next_pos)
		current = next_pos

		# Safety check to prevent infinite loops
		if path.size() > 50:
			break

	# Ensure we end at the target
	if current != target:
		path.append(target)

	return path

static func generate_snake_path(start_pos: Vector2, end_pos: Vector2, grid_size: int) -> Array:
	var path = []
	var current = start_pos
	var target = end_pos

	# Create a snake-like path with turns
	var turns = 0
	var max_turns = 4
	var direction = Vector2(-grid_size, 0)  # Start going left

	while current.distance_to(target) > grid_size * 2 and turns < max_turns:
		# Move in current direction for a while
		var steps = randi_range(3, 8)
		for i in steps:
			var next_pos = current + direction
			# Keep within screen bounds
			next_pos = BoundsHelper.clamp_to_screen(next_pos)

			path.append(next_pos)
			current = next_pos

			if current.distance_to(target) < grid_size * 2:
				break

		# Change direction towards target
		var direction_to_target = (target - current).normalized()
		if abs(direction_to_target.x) > abs(direction_to_target.y):
			direction = Vector2(-grid_size if direction_to_target.x < 0 else grid_size, 0)
		else:
			direction = Vector2(0, -grid_size if direction_to_target.y < 0 else grid_size)

		turns += 1

	# Final approach to target
	while current.distance_to(target) > grid_size:
		var direction_to_target = (target - current).normalized()
		var next_pos = current

		if abs(direction_to_target.x) > abs(direction_to_target.y):
			next_pos.x += grid_size if direction_to_target.x > 0 else -grid_size
		else:
			next_pos.y += grid_size if direction_to_target.y > 0 else -grid_size

		path.append(next_pos)
		current = next_pos

	path.append(target)
	return path

static func generate_spiral_path(start_pos: Vector2, end_pos: Vector2, grid_size: int) -> Array:
	var path = []
	var current = start_pos
	var target = end_pos

	# Create a spiral approaching the center
	var center = Vector2(400, 300)  # Slightly left of screen center
	var radius = 150  # Smaller radius to stay on screen
	var angle = 0.0
	var spiral_steps = 15  # Fewer steps

	for i in spiral_steps:
		angle += PI / 3  # 60 degrees per step
		radius *= 0.85   # Spiral inward faster

		var spiral_pos = center + Vector2(cos(angle), sin(angle)) * radius

		# Snap to grid first
		spiral_pos.x = round(spiral_pos.x / grid_size) * grid_size
		spiral_pos.y = round(spiral_pos.y / grid_size) * grid_size

		# Keep within screen bounds
		spiral_pos = BoundsHelper.clamp_to_screen(spiral_pos)

		path.append(spiral_pos)
		current = spiral_pos

		if current.distance_to(target) < grid_size * 3:
			break

	# Final approach to target
	path.append(target)
	return path