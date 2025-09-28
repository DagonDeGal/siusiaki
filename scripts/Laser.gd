extends Area2D

var speed = 400
var damage = 20
var target
var direction = Vector2.ZERO
var tower_type_to_set = 0

@onready var sprite = $Sprite2D

var laser_textures = {
	0: "res://assets/laserBlue05.png",   # BLUE_UFO
	1: "res://assets/laserGreen05.png",  # GREEN_UFO
	2: "res://assets/laserRed05.png"     # RED_UFO
}

func _ready():
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10, 5)
	$CollisionShape2D.shape = shape

	body_entered.connect(_on_body_entered)

	if tower_type_to_set in laser_textures:
		sprite.texture = load(laser_textures[tower_type_to_set])

func setup(start_pos, enemy_target, laser_damage, tower_type):
	global_position = start_pos
	target = enemy_target
	damage = laser_damage
	tower_type_to_set = tower_type

	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()

	call_deferred("update_texture")

func update_texture():
	if sprite and tower_type_to_set in laser_textures:
		sprite.texture = load(laser_textures[tower_type_to_set])

func _process(delta):
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta

		if global_position.distance_to(Vector2.ZERO) > 2000:
			queue_free()

func _on_body_entered(body):
	if body == target and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body.has_method("take_damage") and body != target:
		body.take_damage(damage)
		queue_free()