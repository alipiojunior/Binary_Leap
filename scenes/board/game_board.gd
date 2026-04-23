extends Node

signal update_state(old_state, new_state)
signal update_index(old_index, new_index)
signal solved

@export var target: String = "11110011"
var current_display: String = ""
var current_index: int = -1
var current_bits: Array = []

var broken_bits: Array = []

func _ready():
	reset_board()

func _unhandled_input(event):
	var old_index = current_index
	
	if event.is_action_pressed("ui_right") or event.is_action_pressed("D"):
		var next_index = current_index + 1
		if next_index < target.length() and not next_index in broken_bits:
			current_index = next_index
			_change_bit(1)
			update_index.emit(old_index, current_index)
			
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("A"):
		var next_index = current_index - 1
		if next_index >= 0 and not next_index in broken_bits:
			current_index = next_index
			_change_bit(0)
			update_index.emit(old_index, current_index)

func _change_bit(new_value):
	var old_state = current_bits.duplicate()
	current_bits[current_index] = new_value
	current_display = arr_to_binstr(current_bits)
	update_state.emit(old_state, current_bits)
	
	if current_display == target:
		solved.emit()

func arr_to_binstr(arr):
	var s = ""
	for b in arr:
		s += str(b)
	return s

func reset_board():
	current_index = -1
	broken_bits = []
	current_bits.clear()
	for i in range(target.length()):
		current_bits.append(0)
	current_display = arr_to_binstr(current_bits)
