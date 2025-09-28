extends Node2D

var radius = 100
var color = Color.CYAN

func setup(r: float, c: Color):
	radius = r
	color = c

func _draw():
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.15))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(color.r, color.g, color.b, 0.6), 2)