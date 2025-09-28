extends Node

class_name BoundsHelper

# Screen boundaries for path generation
const SCREEN_LEFT = 80
const SCREEN_RIGHT = 920
const SCREEN_TOP = 120
const SCREEN_BOTTOM = 500

static func clamp_to_screen(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, SCREEN_LEFT, SCREEN_RIGHT),
		clamp(pos.y, SCREEN_TOP, SCREEN_BOTTOM)
	)

static func is_within_screen(pos: Vector2) -> bool:
	return pos.x >= SCREEN_LEFT and pos.x <= SCREEN_RIGHT and pos.y >= SCREEN_TOP and pos.y <= SCREEN_BOTTOM

static func get_safe_random_position(grid_size: int) -> Vector2:
	var x = randi_range(SCREEN_LEFT, SCREEN_RIGHT)
	var y = randi_range(SCREEN_TOP, SCREEN_BOTTOM)

	# Snap to grid
	x = round(x / grid_size) * grid_size
	y = round(y / grid_size) * grid_size

	return clamp_to_screen(Vector2(x, y))