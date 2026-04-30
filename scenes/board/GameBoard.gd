class_name GameBoard
extends Node

signal update_state(old_state, new_state)
signal update_index(old_index, new_index)
signal solved()
signal game_started()

enum CellType { STANDARD, FLIP_EVERY_N, BLOCKER, EXPLODING }

## Full board definition containing starting bits and special rules.
## Examples: "1010", "1(0,2)(1,2)0", "1{0,1}1", "0<1,3>1"
@export var board_definition: String = "1010"

## Target pattern to reach (plain "0"/"1" string).
@export var target: String = "0000"

## Starting cursor index (-1 means "off the board", first move goes to index 0).
@export var starting_index: int = -1

var board_size: int
var target_state: Array[bool] = []
var current_state: Array[bool] = []   # live bit values (aliased)
var current_index: int = -1
var current_display: String = ""

# Per‑cell metadata
var cell_types: Array[int] = []       # CellType values
var cell_params: Array[int] = []      # N for special cells, 0 for standard
var cell_counters: Array[int] = []    # visit counter for flip‑every‑N, blocker, exploding

# Explosion chain guard – prevents infinite recursion
var _in_explosion_chain: Array[bool] = []


func _ready() -> void:
	reset_board()


func reset_board() -> void:
	_parse_board_definition(board_definition)
	target_state = binstr_to_arr(target)
	current_index = starting_index
	current_display = arr_to_binstr(current_state)
	# Optionally emit game_started() here if needed


func _process(_delta: float) -> void:
	var moved := false
	var old_state := current_state.duplicate()
	var old_index := current_index

	if Input.is_action_just_pressed("move_left"):
		moved = move_left()
	elif Input.is_action_just_pressed("move_right"):
		moved = move_right()

	if moved:
		update_state.emit(old_state, current_state.duplicate())
		update_index.emit(old_index, current_index)
		current_display = arr_to_binstr(current_state)
		print(current_display)

	_check_solve()


## Attempt to move the cursor one step right.
func move_right() -> bool:
	var new_index := 0 if current_index == -1 else current_index + 1
	if new_index >= board_size:
		return false
	return _attempt_move(new_index)


## Attempt to move the cursor one step left.
func move_left() -> bool:
	if current_index <= 0:
		return false
	var new_index := current_index - 1
	return _attempt_move(new_index)


## Common logic for a valid move onto a cell.
func _attempt_move(new_index: int) -> bool:
	# Blocker that has reached its limit → impassable (cursor cannot enter)
	if cell_types[new_index] == CellType.BLOCKER and cell_counters[new_index] >= cell_params[new_index]:
		return false

	# Clear recursion guard for this move
	for i in board_size:
		_in_explosion_chain[i] = false

	# Process the cell as if the cursor landed on it (full behaviour)
	_apply_visit(new_index)

	current_index = new_index
	return true


## Simulate a visit to a cell – increments its counter and applies all rules,
## including possible chain explosions.
func _apply_visit(index: int) -> void:
	# Prevent re‑entering a cell that is already being processed in an explosion chain
	if _in_explosion_chain[index]:
		return

	# Blocker that has already blocked is immune to explosions (and anything else)
	if cell_types[index] == CellType.BLOCKER and cell_counters[index] >= cell_params[index]:
		return

	# One “visit” to this cell
	cell_counters[index] += 1
	var counter := cell_counters[index]

	match cell_types[index]:
		CellType.STANDARD, CellType.BLOCKER:
			# Standard and blocker cells flip every time they are visited
			current_state[index] = not current_state[index]

		CellType.FLIP_EVERY_N:
			var n := cell_params[index]
			if n > 0 and counter % n == 0:
				current_state[index] = not current_state[index]

		CellType.EXPLODING:
			# Always flips itself
			current_state[index] = not current_state[index]

			# If this is a multiple‑of‑N visit, also affect neighbours
			var n := cell_params[index]
			if n > 0 and counter % n == 0:
				# Set flag to prevent infinite recursion
				_in_explosion_chain[index] = true

				var left_neighbour := index - 1
				var right_neighbour := index + 1

				if left_neighbour >= 0:
					_apply_visit(left_neighbour)
				if right_neighbour < board_size:
					_apply_visit(right_neighbour)

				_in_explosion_chain[index] = false


## Check victory condition.
func _check_solve() -> void:
	if current_state == target_state:
		solved.emit()


# ------------------------------------------------------------------ #
#  Parsing                                                           #
# ------------------------------------------------------------------ #

func _parse_board_definition(def: String) -> void:
	cell_types.clear()
	current_state.clear()
	cell_params.clear()
	cell_counters.clear()

	var i := 0
	while i < def.length():
		var ch := def[i]

		# Skip whitespace
		if ch == ' ' or ch == '\t' or ch == '\n':
			i += 1
			continue

		# Standard bit: '0' or '1'
		if ch == '0' or ch == '1':
			current_state.append(ch == '1')
			cell_types.append(CellType.STANDARD)
			cell_params.append(0)
			cell_counters.append(0)
			i += 1

		# Flip‑every‑N: '(' value ',' N ')'
		elif ch == '(':
			i += 1
			var val := _parse_digit(def, i); i += 1
			if i >= def.length() or def[i] != ',':
				push_error("Malformed (value,N): missing comma")
				return
			i += 1
			var n := _parse_integer(def, i); i = _skip_digits(def, i)
			if i >= def.length() or def[i] != ')':
				push_error("Malformed (value,N): missing closing )")
				return
			i += 1

			current_state.append(val == 1)
			cell_types.append(CellType.FLIP_EVERY_N)
			cell_params.append(n)
			cell_counters.append(0)

		# Blocker: '{' value ',' N '}'
		elif ch == '{':
			i += 1
			var val := _parse_digit(def, i); i += 1
			if i >= def.length() or def[i] != ',':
				push_error("Malformed {value,N}: missing comma")
				return
			i += 1
			var n := _parse_integer(def, i); i = _skip_digits(def, i)
			if i >= def.length() or def[i] != '}':
				push_error("Malformed {value,N}: missing closing }")
				return
			i += 1

			current_state.append(val == 1)
			cell_types.append(CellType.BLOCKER)
			cell_params.append(n)
			cell_counters.append(0)

		# Exploding: '<' value ',' N '>'
		elif ch == '<':
			i += 1
			var val := _parse_digit(def, i); i += 1
			if i >= def.length() or def[i] != ',':
				push_error("Malformed <value,N>: missing comma")
				return
			i += 1
			var n := _parse_integer(def, i); i = _skip_digits(def, i)
			if i >= def.length() or def[i] != '>':
				push_error("Malformed <value,N>: missing closing >")
				return
			i += 1

			current_state.append(val == 1)
			cell_types.append(CellType.EXPLODING)
			cell_params.append(n)
			cell_counters.append(0)

		else:
			push_error("Invalid character in board definition: " + ch)
			i += 1

	board_size = current_state.size()

	# Prepare guard array for explosion chains
	_in_explosion_chain.clear()
	_in_explosion_chain.resize(board_size)
	_in_explosion_chain.fill(false)


func _parse_digit(s: String, idx: int) -> int:
	if idx >= s.length() or s[idx] not in ['0', '1']:
		push_error("Expected '0' or '1' at position %d" % idx)
		return 0
	return 1 if s[idx] == '1' else 0


func _parse_integer(s: String, idx: int) -> int:
	var start := idx
	while idx < s.length() and s[idx].is_valid_int():
		idx += 1
	if idx == start:
		push_error("Expected integer at position %d" % start)
		return 1
	return int(s.substr(start, idx - start))


func _skip_digits(s: String, idx: int) -> int:
	while idx < s.length() and s[idx].is_valid_int():
		idx += 1
	return idx


# ------------------------------------------------------------------ #
#  Utility converters (unchanged from original)                      #
# ------------------------------------------------------------------ #

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
