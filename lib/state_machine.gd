class_name StateMachine extends Node

@export var initial_state: State = null
@onready var current_state: State = initial_state if initial_state != null else get_child(0)

func _ready() -> void:
	for state_node: State in find_children("*", "State"):
		state_node.transition_to.connect(_transition)

	current_state.on_enter("")

func _transition(target_state: String) -> void:
	if not has_node(target_state):
		return
		
	var previous_state_name: String = current_state.name
	
	current_state.on_exit() 
	
	current_state = get_node(target_state)
	current_state.on_enter(previous_state_name)


func _process(delta: float) -> void:
	current_state.update(delta)
func _physics_process(delta: float) -> void:
	current_state.physics_update(delta)
