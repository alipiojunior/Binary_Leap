class_name State extends Node

signal transition_to(next_state: String)

func update(_delta: float) -> void:
	pass
func physics_update(_delta: float) -> void:
	pass

func on_enter(previous_state: String) -> void:
	pass
func on_exit() -> void:
	pass
