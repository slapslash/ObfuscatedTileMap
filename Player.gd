extends KinematicBody2D

onready var visibility_range = $"VisibilityRange"

var speed = 50

signal visibility_range_changed(area2d)


func _ready():
	emit_signal("visibility_range_changed", visibility_range)


func _process(delta):
	var move = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		move += Vector2(0, -speed)
	if Input.is_action_pressed("ui_down"):
		move += Vector2(0, speed)
	if Input.is_action_pressed("ui_left"):
		move += Vector2(-speed, 0)
	if Input.is_action_pressed("ui_right"):
		move += Vector2(speed, 0)
	
	var _e = move_and_collide(move * delta)
	if move != Vector2.ZERO:
		emit_signal("visibility_range_changed", visibility_range)
