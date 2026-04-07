class_name GameBoard
extends Node

signal update_state(old_state, new_state)
signal update_index(old_index, new_index)
signal solved()
signal game_started()

@export var target = "00000000"
@export var start = "00000000"
@export var starting_index: int = -1

@onready var board_size = target.length()
var target_state: Array[bool] = []
var current_state: Array[bool] = []
var current_index: int = -1
var current_display = "00000000"

func _check_solve():
	if current_state == target_state:
		solved.emit()
		
func reset_board():
	target_state = binstr_to_arr(target)
	current_state = binstr_to_arr(start)
	current_display = arr_to_binstr(current_state)
	current_index = starting_index

func _process(_delta):
	var results = null
	if Input.is_action_just_pressed("move_left"):
		results = move_left(current_state, current_index)
	elif Input.is_action_just_pressed("move_right"):
		results = move_right(current_state, current_index)
	
	if results != null:
		var new_state = results[0]
		var new_index = results[1]
		
		update_state.emit(current_state.duplicate(), new_state)
		update_index.emit(current_index, new_index)
		
		current_state = new_state
		current_index = new_index
		current_display = arr_to_binstr(current_state)
		
	_check_solve()

func move_right(state: Array[bool], index: int):
	# If index is -1, just move to 0 without flipping
	if index == -1:
		var new_state = state.duplicate()
		return [new_state, 0]
	
	if index + 1 >= board_size:
		return null
	else:
		var new_state = state.duplicate()
		var new_index = index + 1
		new_state[new_index] = !new_state[new_index]
		return [new_state, new_index]

func move_left(state: Array[bool], index: int):
	if index <= 0:
		return null
	else:
		var new_state = state.duplicate()
		var new_index = index - 1
		new_state[new_index] = !new_state[new_index]
		return [new_state, new_index]

func binstr_to_arr(bin_str: String) -> Array[bool]:
	var bits: Array[bool] = []
	for ch in bin_str:
		if ch == " " or ch == "\t" or ch == "\n":
			continue
		if ch == "0":
			bits.append(false)
		elif ch == "1":
			bits.append(true)
		else:
			push_error("Invalid binary character: ", ch)
	return bits

func arr_to_binstr(bits: Array[bool]) -> String:
	var result = ""
	for bit in bits:
		result += "1" if bit else "0"
	return result
