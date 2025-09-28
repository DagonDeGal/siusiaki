extends CharacterBody2D

enum EnemyType { BLUE_FISH, BROWN_FISH, SKELETON }

var enemy_type = EnemyType.BLUE_FISH
var max_health = 50
var current_health = 50
var speed = 100
var damage = 10
var reward = 10
var target_position = Vector2.ZERO
var enemy_path = []
var current_path_index = 0
var path_progress = 0.0  # Progress along current path segment (0.0 to 1.0)
var main_scene

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var textures = {
	EnemyType.BLUE_FISH: "res://assets/fish_blue_outline.png",
	EnemyType.BROWN_FISH: "res://assets/fish_brown_outline.png",
	EnemyType.SKELETON: "res://assets/fish_red_skeleton_outline.png"
}

func _ready():
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	$CollisionShape2D.shape = shape

	randomize_enemy_type()
	setup_enemy_stats()
	update_health_bar()

func randomize_enemy_type():
	var rand = randi() % 3
	enemy_type = rand as EnemyType

func setup_enemy_stats():
	match enemy_type:
		EnemyType.BLUE_FISH:
			max_health = 30
			speed = 120
			damage = 5
			reward = 10
		EnemyType.BROWN_FISH:
			max_health = 60
			speed = 80
			damage = 10
			reward = 20
		EnemyType.SKELETON:
			max_health = 100
			speed = 60
			damage = 20
			reward = 35

	current_health = max_health
	sprite.texture = load(textures[enemy_type])

func _physics_process(delta):
	if enemy_path.size() > 0:
		move_along_path(delta)
	elif target_position != Vector2.ZERO:
		move_to_target(delta)

func move_along_path(delta):
	if current_path_index >= enemy_path.size():
		attack_base()
		return

	# Get current and next waypoint
	var current_waypoint = global_position
	var next_waypoint = enemy_path[current_path_index]

	if current_path_index == 0:
		# First waypoint - move from spawn position
		current_waypoint = global_position
	else:
		# Get previous waypoint for smooth interpolation
		current_waypoint = enemy_path[current_path_index - 1]

	# Calculate distance to travel this frame
	var segment_length = current_waypoint.distance_to(next_waypoint)

	if segment_length < 1.0:  # Very short segment, skip it
		current_path_index += 1
		path_progress = 0.0
		return

	# Calculate how much we move along this segment
	var distance_per_frame = speed * delta
	var progress_increment = distance_per_frame / segment_length

	# Update progress
	path_progress += progress_increment

	if path_progress >= 1.0:
		# Reached next waypoint
		path_progress = 0.0
		current_path_index += 1

		if current_path_index >= enemy_path.size():
			# Reached end of path, go to base
			global_position = next_waypoint
			attack_base()
			return

	# Interpolate position between current and next waypoint
	var new_position = current_waypoint.lerp(next_waypoint, path_progress)

	# Calculate movement direction for this frame
	var movement_direction = (new_position - global_position).normalized()

	# Rotate sprite to face movement direction
	if movement_direction.length() > 0.1:
		sprite.rotation = movement_direction.angle()

	# Set velocity for smooth movement
	velocity = movement_direction * speed
	move_and_slide()

func move_to_target(delta):
	var direction = (target_position - global_position).normalized()

	# Rotate sprite to face movement direction
	if direction.length() > 0.1:
		sprite.rotation = direction.angle()

	velocity = direction * speed
	move_and_slide()

	if global_position.distance_to(target_position) < 20:
		attack_base()

func take_damage(amount):
	current_health -= amount
	update_health_bar()

	if current_health <= 0:
		die()

func update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = current_health

func attack_base():
	if main_scene:
		main_scene.take_damage(damage)
		main_scene.remove_enemy(self)
	queue_free()

func die():
	if main_scene:
		main_scene.add_money(reward)
		main_scene.remove_enemy(self)
	queue_free()