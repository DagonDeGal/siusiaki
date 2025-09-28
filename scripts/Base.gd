extends Area2D

func _ready():
	var shape = CircleShape2D.new()
	shape.radius = 30
	$CollisionShape2D.shape = shape

	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("attack_base"):
		body.attack_base()