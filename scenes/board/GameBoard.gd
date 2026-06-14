class_name GameBoard
extends Node

signal update_state(old_state, new_state)
signal update_index(old_index, new_index)
signal move_count_changed(new_count: int)
signal solved()

enum CellType { STANDARD, DELAYED }

@export var board_definition: String = "1010"
@export var target: String = "0000"
@export var starting_index: int = -1
@export var move_budget: int = 0

var board_size: int
var target_state: Array[bool] = []
var current_state: Array[bool] = []
var current_index: int = -1
var current_display: String = ""
var move_count: int = 0

var cell_types: Array[int] = []
var cell_counters: Array[int] = []

var _history: Array = []
var is_solved = false

func _ready() -> void:
	reset_board()

func reset_board() -> void:
	_parse_board_definition(board_definition)
	target_state = binstr_to_arr(target)
	current_index = starting_index
	current_display = arr_to_binstr(current_state)
	move_count = 0
	is_solved = false
	_history.clear()

func _process(_delta: float) -> void:
	var moved := false
	var old_state := current_state.duplicate()
	var old_index := current_index
	
	if Input.is_action_just_pressed("move_left"):
		moved = move_left()
	elif Input.is_action_just_pressed("move_right"):
		moved = move_right()
	elif Input.is_action_just_pressed("undo"):
		undo()
		return
	
	if moved:
		update_state.emit(old_state, current_state.duplicate())
		update_index.emit(old_index, current_index)
		current_display = arr_to_binstr(current_state)
	
	_check_solve()

func move_right() -> bool:
	var new_index := 0 if current_index == -1 else current_index + 1
	if new_index >= board_size:
		return false
	return _attempt_move(new_index)

func move_left() -> bool:
	if current_index <= 0:
		return false
	return _attempt_move(current_index - 1)

func _attempt_move(new_index: int) -> bool:
	_history.append({
		"state": current_state.duplicate(),
		"index": current_index,
		"counters": cell_counters.duplicate(),
		"move_count": move_count
	})
	_apply_visit(new_index)
	current_index = new_index
	move_count += 1
	move_count_changed.emit(move_count)
	return true

func undo() -> void:
	if _history.is_empty():
		return
	var snapshot = _history.pop_back()
	var old_state := current_state.duplicate()
	var old_index := current_index
	current_state = snapshot["state"]
	current_index = snapshot["index"]
	cell_counters = snapshot["counters"]
	move_count = snapshot["move_count"]
	current_display = arr_to_binstr(current_state)
	update_state.emit(old_state, current_state.duplicate())
	update_index.emit(old_index, current_index)
	move_count_changed.emit(move_count)

func _apply_visit(index: int) -> void:
	cell_counters[index] += 1
	match cell_types[index]:
		CellType.STANDARD:
			current_state[index] = not current_state[index]
		CellType.DELAYED:
			if cell_counters[index] % 2 == 0:
				current_state[index] = not current_state[index]

func _check_solve() -> void:
	if current_state == target_state and not is_solved:
		is_solved = true
		solved.emit()

func _parse_board_definition(def: String) -> void:
	cell_types.clear()
	current_state.clear()
	cell_counters.clear()

	var i := 0
	while i < def.length():
		var ch := def[i]
		
		if ch == ' ' or ch == '\t' or ch == '\n':
			i += 1
			continue
		
		if ch == '0' or ch == '1':
			current_state.append(ch == '1')
			cell_types.append(CellType.STANDARD)
			cell_counters.append(0)
			i += 1
		
		elif ch == '(':
			i += 1
			var val := _parse_digit(def, i); i += 1
			if i >= def.length() or def[i] != ')':
				push_error("Malformed (value): missing closing )")
				return
			i += 1
			current_state.append(val == 1)
			cell_types.append(CellType.DELAYED)
			cell_counters.append(0)
		
		else:
			push_error("Invalid character in board definition: " + ch)
			i += 1

	board_size = current_state.size()

func _parse_digit(s: String, idx: int) -> int:
	if idx >= s.length() or s[idx] not in ['0', '1']:
		push_error("Expected '0' or '1' at position %d" % idx)
		return 0
	return 1 if s[idx] == '1' else 0

func binstr_to_arr(bin_str: String) -> Array[bool]:
	var bits: Array[bool] = []
	for ch in bin_str:
		if ch == ' ' or ch == '\t' or ch == '\n':
			continue
		if ch == '0':
			bits.append(false)
		elif ch == '1':
			bits.append(true)
		else:
			push_error("Invalid binary character: ", ch)
	return bits

func arr_to_binstr(bits: Array[bool]) -> String:
	var result := ""
	for bit in bits:
		result += "1" if bit else "0"
	return result
