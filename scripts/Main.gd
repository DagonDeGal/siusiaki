extends Node2D

var health = 100
var money = 100
var wave = 1
var base_position = Vector2(100, 300)

# Grid system
var grid_size = 40
var grid_width = 24  # Reduced from 30 to fit better
var grid_height = 15  # Reduced from 20 to fit better
var grid_offset = Vector2(0, 0)
var show_range_preview = false
var preview_range_circles = []

@onready var health_label = $UI/HUD/HealthLabel
@onready var wave_label = $UI/HUD/WaveLabel
@onready var money_label = $UI/HUD/MoneyLabel
@onready var path_label = $UI/HUD/PathLabel
@onready var game_area = $GameArea

var enemy_scene = preload("res://scenes/Enemy.tscn")
var tower_scene = preload("res://scenes/Tower.tscn")
var base_scene = preload("res://scenes/Base.tscn")

var enemies = []
var towers = []
var wave_timer = 0.0
var spawn_timer = 0.0
var enemies_spawned = 0
var max_enemies_per_wave = 5
var spawn_points = [Vector2(920, 200), Vector2(920, 300), Vector2(920, 400)]
var enemy_path = []
var current_path_type = 0  # 0=maze, 1=snake, 2=spiral
var path_visual_nodes = []

func _ready():
	spawn_base()
	generate_new_path()
	draw_path()
	draw_grid()
	update_ui()

func _process(delta):
	wave_timer += delta
	spawn_timer += delta

	if spawn_timer > 1.5 and enemies_spawned < max_enemies_per_wave:
		spawn_enemy()
		spawn_timer = 0.0
		enemies_spawned += 1

	if enemies_spawned >= max_enemies_per_wave and enemies.is_empty():
		start_next_wave()

func spawn_base():
	var base = base_scene.instantiate()
	base.position = base_position
	game_area.add_child(base)

func spawn_enemy():
	if enemy_path.is_empty():
		generate_new_path()

	var enemy = enemy_scene.instantiate()
	# Start enemy at random spawn point
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	enemy.position = spawn_point

	# Create full path: spawn_point -> path -> base
	var full_path = []
	if enemy_path.size() > 0:
		full_path.append(enemy_path[0])  # First waypoint
		for i in range(1, enemy_path.size()):
			full_path.append(enemy_path[i])
	full_path.append(base_position)  # Final destination

	enemy.target_position = base_position
	enemy.enemy_path = full_path
	enemy.main_scene = self
	game_area.add_child(enemy)
	enemies.append(enemy)

func generate_new_path():
	# Choose random spawn point and target base
	var start_point = spawn_points[randi() % spawn_points.size()]
	var end_point = base_position

	# Cycle through different path types
	match current_path_type:
		0:  # Maze path
			enemy_path = PathGenerator.generate_maze_path(start_point, end_point, grid_size)
		1:  # Snake path
			enemy_path = PathGenerator.generate_snake_path(start_point, end_point, grid_size)
		2:  # Spiral path
			enemy_path = PathGenerator.generate_spiral_path(start_point, end_point, grid_size)

	# Cycle to next path type for next wave
	current_path_type = (current_path_type + 1) % 3

	print("Generated new path type: ", ["Maze", "Snake", "Spiral"][current_path_type])

func start_next_wave():
	wave += 1
	enemies_spawned = 0
	max_enemies_per_wave += 3
	spawn_timer = 0.0

	# Generate new path every few waves
	if wave % 2 == 0:  # Every 2nd wave gets new path
		clear_path_visuals()
		generate_new_path()
		draw_path()

	update_ui()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = snap_to_grid(mouse_pos)

		if event.button_index == MOUSE_BUTTON_LEFT:
			place_tower(snapped_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			clear_range_preview()
			print("Right click - tower placement cancelled")

	elif event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = snap_to_grid(mouse_pos)
		show_tower_range_preview(snapped_pos)

func place_tower(pos):
	if money >= 50:
		if not is_position_blocked(pos):
			var tower = tower_scene.instantiate()
			tower.position = pos
			tower.main_scene = self
			game_area.add_child(tower)
			towers.append(tower)
			money -= 50
			update_ui()
		else:
			print("Cannot place tower here - position blocked")
	else:
		print("Not enough money! Need 50, have " + str(money))

func is_position_blocked(pos):
	if pos.distance_to(base_position) < 60:
		return true

	for point in enemy_path:
		if pos.distance_to(point) < 40:
			return true

	for tower in towers:
		if is_instance_valid(tower) and pos.distance_to(tower.position) < 50:
			return true

	return false

func take_damage(amount):
	health -= amount
	update_ui()
	if health <= 0:
		game_over()

func add_money(amount):
	money += amount
	update_ui()

func remove_enemy(enemy):
	if enemy in enemies:
		enemies.erase(enemy)

func game_over():
	print("Game Over! You reached wave " + str(wave))
	get_tree().paused = true

	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER!\nWave: " + str(wave) + "\nPress R to restart"
	game_over_label.add_theme_font_size_override("font_size", 32)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(game_over_label)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				if get_tree().paused:
					get_tree().paused = false
					get_tree().reload_current_scene()
			KEY_P:
				# Manual path regeneration
				clear_path_visuals()
				generate_new_path()
				draw_path()
				print("New path generated manually!")

func draw_grid():
	for x in range(grid_width):
		for y in range(grid_height):
			var grid_pos = Vector2(x * grid_size + grid_offset.x, y * grid_size + grid_offset.y)
			var grid_cell = ColorRect.new()
			grid_cell.size = Vector2(grid_size - 2, grid_size - 2)
			grid_cell.position = grid_pos + Vector2(1, 1)
			grid_cell.color = Color(0.2, 0.2, 0.2, 0.3)
			grid_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			game_area.add_child(grid_cell)

func snap_to_grid(pos: Vector2) -> Vector2:
	var grid_x = round((pos.x - grid_offset.x) / grid_size) * grid_size + grid_offset.x
	var grid_y = round((pos.y - grid_offset.y) / grid_size) * grid_size + grid_offset.y
	return Vector2(grid_x, grid_y)

func clear_path_visuals():
	for node in path_visual_nodes:
		if is_instance_valid(node):
			node.queue_free()
	path_visual_nodes.clear()

func draw_path():
	if enemy_path.is_empty():
		return

	# Draw spawn points
	for spawn_point in spawn_points:
		var spawn_marker = ColorRect.new()
		spawn_marker.size = Vector2(15, 15)
		spawn_marker.position = spawn_point - Vector2(7.5, 7.5)
		spawn_marker.color = Color.RED
		game_area.add_child(spawn_marker)
		path_visual_nodes.append(spawn_marker)

		# Connect spawn points to first path point
		if enemy_path.size() > 0:
			var line_to_path = Line2D.new()
			line_to_path.add_point(spawn_point)
			line_to_path.add_point(enemy_path[0])
			line_to_path.width = 2
			line_to_path.default_color = Color.ORANGE
			game_area.add_child(line_to_path)
			path_visual_nodes.append(line_to_path)

	# Draw path points and connections with different colors for different path types
	var path_colors = [Color.CYAN, Color.MAGENTA, Color.YELLOW]  # Maze, Snake, Spiral
	var current_color = path_colors[current_path_type]

	for i in range(enemy_path.size()):
		var path_marker = ColorRect.new()
		path_marker.size = Vector2(8, 8)
		path_marker.position = enemy_path[i] - Vector2(4, 4)
		path_marker.color = current_color
		game_area.add_child(path_marker)
		path_visual_nodes.append(path_marker)

		if i > 0:
			var line = Line2D.new()
			line.add_point(enemy_path[i-1])
			line.add_point(enemy_path[i])
			line.width = 4
			line.default_color = current_color
			game_area.add_child(line)
			path_visual_nodes.append(line)

	# Draw line from last path point to base
	if enemy_path.size() > 0:
		var line_to_base = Line2D.new()
		line_to_base.add_point(enemy_path[-1])
		line_to_base.add_point(base_position)
		line_to_base.width = 4
		line_to_base.default_color = Color.GREEN
		game_area.add_child(line_to_base)
		path_visual_nodes.append(line_to_base)

func show_tower_range_preview(pos: Vector2):
	if money >= 50 and not is_position_blocked(pos):
		clear_range_preview()

		# Show range for potential tower (use average range)
		var range_radius = 120.0  # Blue tower range as default

		# Create simple circular range indicator
		create_range_circle(pos, range_radius, Color.CYAN)

		# Highlight grid cells within range
		highlight_attackable_area(pos, range_radius)

func create_range_circle(pos: Vector2, radius: float, color: Color):
	var range_node = Node2D.new()
	range_node.position = pos

	var range_script = GDScript.new()
	range_script.source_code = """
extends Node2D

var radius = 100.0
var color = Color.CYAN

func setup(r: float, c: Color):
	radius = r
	color = c
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.15))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(color.r, color.g, color.b, 0.6), 2)
"""

	range_node.set_script(range_script)
	game_area.add_child(range_node)
	preview_range_circles.append(range_node)

	# Call setup after node is in scene tree
	range_node.call_deferred("setup", radius, color)

func clear_range_preview():
	for circle in preview_range_circles:
		if is_instance_valid(circle):
			circle.queue_free()
	preview_range_circles.clear()

func highlight_attackable_area(tower_pos: Vector2, range_radius: float):
	for x in range(grid_width):
		for y in range(grid_height):
			var grid_pos = Vector2(x * grid_size + grid_offset.x + grid_size/2, y * grid_size + grid_offset.y + grid_size/2)
			var distance = tower_pos.distance_to(grid_pos)

			if distance <= range_radius:
				var highlight = ColorRect.new()
				highlight.size = Vector2(grid_size - 4, grid_size - 4)
				highlight.position = Vector2(x * grid_size + grid_offset.x + 2, y * grid_size + grid_offset.y + 2)
				highlight.color = Color(1, 1, 0, 0.4)  # Yellow highlight
				highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
				game_area.add_child(highlight)
				preview_range_circles.append(highlight)

func update_ui():
	health_label.text = "Health: " + str(health)
	wave_label.text = "Wave: " + str(wave)
	money_label.text = "Money: " + str(money)

	var path_names = ["Maze", "Snake", "Spiral"]
	var current_path_name = path_names[(current_path_type - 1) % 3]  # -1 because we increment after generation
	path_label.text = "Path: " + current_path_name