extends Node

@onready var game_board: GameBoard = $GameBoard
@onready var target_label = $Target
@onready var board = $Board
@onready var info_label = $Info
@onready var win_sound = $WinSound
@onready var move_sound = $MoveSound

@export var menu_layer: CanvasLayer
@export var btn_continuar: Button
@export var btn_sair: Button

var reset_dialog: ConfirmationDialog

func _ready():
	_setup_reset_dialog()
	
	if menu_layer:
		menu_layer.hide()
		
	if btn_continuar:
		btn_continuar.pressed.connect(_on_btn_continuar_pressed)
	if btn_sair:
		btn_sair.pressed.connect(_on_btn_sair_pressed)
	
	game_board.reset_board()
	board.init_board(game_board)
	target_label.text = "Target: " + game_board.target

	game_board.solved.connect(_on_board_solved)
	game_board.update_state.connect(_on_state_updated)
	game_board.update_index.connect(_on_index_updated)

func _unhandled_input(event):
	if event.is_action_pressed("reset_game"):
		if menu_layer and menu_layer.visible:
			return 
		reset_dialog.popup_centered()
		
	if event.is_action_pressed("toggle_menu"):
		_toggle_menu()

func _setup_reset_dialog():
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "Aviso"
	reset_dialog.dialog_text = "Você deseja reiniciar a partida?"
	reset_dialog.ok_button_text = "SIM"
	reset_dialog.cancel_button_text = "NÃO"
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	add_child(reset_dialog)

func _on_reset_confirmed():
	game_board.reset_board()
	board.init_board(game_board)
	_update_info_label()

func _toggle_menu():
	if menu_layer:
		menu_layer.visible = !menu_layer.visible

func _on_btn_continuar_pressed():
	if menu_layer:
		menu_layer.hide()

func _on_btn_sair_pressed():
	get_tree().quit()

func _on_state_updated(_old_state, new_state: Array):
	_update_info_label()
	if move_sound:
		move_sound.play()

func _on_index_updated(_old_index: int, _new_index: int):
	_update_info_label()

func _on_board_solved():
	if win_sound and not win_sound.playing:
		win_sound.play()

func _update_info_label():
	if not info_label:
		return
	var parts: Array[String] = []
	for i in game_board.board_size:
		var c = game_board.cell_counters[i]
		var t = game_board.cell_types[i]
		var s: String
		match t:
			GameBoard.CellType.STANDARD:       s = str(c)
			GameBoard.CellType.FLIP_EVERY_N:   s = "(" + str(c) + ")"
			GameBoard.CellType.BLOCKER:        s = "{" + str(c) + "}"
			GameBoard.CellType.EXPLODING:      s = "<" + str(c) + ">"
			_:                                 s = "?" + str(c) + "?"
		parts.append(s)
	info_label.text = "[center]" + " ".join(parts) + "[/center]"
