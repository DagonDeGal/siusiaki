extends Area2D

enum TowerType { BLUE_UFO, GREEN_UFO, RED_UFO }

var tower_type = TowerType.BLUE_UFO
var damage = 20
var range_radius = 150
var shoot_interval = 1.0
var main_scene

@onready var sprite = $Sprite2D
@onready var range_area = $Range
@onready var shoot_timer = $ShootTimer

var laser_scene = preload("res://scenes/Laser.tscn")
var enemies_in_range = []
var range_display_node = null
var show_range = false

var textures = {
	TowerType.BLUE_UFO: "res://assets/ufoBlue.png",
	TowerType.GREEN_UFO: "res://assets/ufoGreen.png",
	TowerType.RED_UFO: "res://assets/ufoRed.png"
}

func _ready():
	# Setup click detection
	var click_shape = CircleShape2D.new()
	click_shape.radius = 25
	$ClickArea.shape = click_shape

	randomize_tower_type()
	setup_tower_stats()
	setup_range()

	range_area.body_entered.connect(_on_enemy_entered_range)
	range_area.body_exited.connect(_on_enemy_exited_range)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	input_event.connect(_on_tower_clicked)

func _on_tower_clicked(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_range_display()

func randomize_tower_type():
	var rand = randi() % 3
	tower_type = rand as TowerType

func setup_tower_stats():
	match tower_type:
		TowerType.BLUE_UFO:
			damage = 20
			range_radius = 120
			shoot_interval = 1.0
		TowerType.GREEN_UFO:
			damage = 35
			range_radius = 100
			shoot_interval = 1.5
		TowerType.RED_UFO:
			damage = 50
			range_radius = 80
			shoot_interval = 2.0

	sprite.texture = load(textures[tower_type])
	shoot_timer.wait_time = shoot_interval

func setup_range():
	var shape = CircleShape2D.new()
	shape.radius = range_radius
	$Range/RangeShape.shape = shape

func _on_enemy_entered_range(body):
	if body.has_method("take_damage"):
		enemies_in_range.append(body)

func _on_enemy_exited_range(body):
	if body in enemies_in_range:
		enemies_in_range.erase(body)

func _on_shoot_timer_timeout():
	if not enemies_in_range.is_empty():
		var target = get_closest_enemy()
		if target:
			shoot_laser(target)

func get_closest_enemy():
	if enemies_in_range.is_empty():
		return null

	var closest = enemies_in_range[0]
	var closest_distance = global_position.distance_to(closest.global_position)

	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			enemies_in_range.erase(enemy)
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest = enemy
			closest_distance = distance

	return closest

func shoot_laser(target):
	var laser = laser_scene.instantiate()
	laser.setup(global_position, target, damage, tower_type)
	get_parent().add_child(laser)

func toggle_range_display():
	show_range = !show_range
	if show_range:
		show_tower_range()
	else:
		hide_tower_range()

func show_tower_range():
	hide_tower_range()  # Clear any existing display

	range_display_node = Node2D.new()
	range_display_node.position = global_position

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
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(color.r, color.g, color.b, 0.8), 3)
"""

	range_display_node.set_script(range_script)
	get_parent().add_child(range_display_node)

	var tower_color = Color.CYAN
	match tower_type:
		TowerType.BLUE_UFO:
			tower_color = Color.CYAN
		TowerType.GREEN_UFO:
			tower_color = Color.GREEN
		TowerType.RED_UFO:
			tower_color = Color.RED

	# Call setup after node is in scene tree
	range_display_node.call_deferred("setup", range_radius, tower_color)

func hide_tower_range():
	if range_display_node and is_instance_valid(range_display_node):
		range_display_node.queue_free()
		range_display_node = null