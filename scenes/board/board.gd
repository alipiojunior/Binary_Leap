class_name Board
extends HBoxContainer

var cells: Array[Cell] = []
var game_board: GameBoard = null

func init_board(p_game_board: GameBoard):
	game_board = p_game_board
	_clear_cells()

	for i in game_board.board_size:
		var cell_scene = preload("res://scenes/board/Cell.tscn")
		var cell = cell_scene.instantiate()
		add_child(cell)
		cells.append(cell)

		cell.setup(
			i,
			game_board.cell_types[i],
			game_board.cell_params[i],
			game_board.current_state[i]
		)
		cell.update_counter(game_board.cell_counters[i])

	game_board.update_state.connect(_on_state_changed)
	game_board.update_index.connect(_on_index_changed)

	_set_current_cell(game_board.current_index)

func _clear_cells():
	for c in cells:
		c.queue_free()
	cells.clear()

func _on_state_changed(_old_state, new_state: Array):
	for i in game_board.board_size:
		cells[i].update_state(game_board.current_state[i])
		cells[i].update_counter(game_board.cell_counters[i])

		if game_board.cell_types[i] == GameBoard.CellType.BLOCKER and game_board.cell_counters[i] >= game_board.cell_params[i]:
			cells[i].set_blocked(true)
		else:
			cells[i].set_blocked(false)

func _on_index_changed(old_index: int, new_index: int):
	if old_index >= 0 and old_index < cells.size():
		cells[old_index].set_current(false)
	_set_current_cell(new_index)

func _set_current_cell(index: int):
	if index >= 0 and index < cells.size():
		cells[index].set_current(true)
