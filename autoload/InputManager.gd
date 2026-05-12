extends Node

signal move_requested(direction: int)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		move_requested.emit(-1)
	elif Input.is_action_just_pressed("move_right"):
		move_requested.emit(+1)
