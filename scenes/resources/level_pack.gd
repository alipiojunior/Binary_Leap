class_name LevelPack
extends Resource

# Maps level name (String) -> LevelSpec.
@export var levels: Dictionary = {}
@export var pack_name: String = ""

func get_level(level_name: String) -> LevelSpec:
	return levels.get(level_name, null)

func get_level_names() -> Array:
	return levels.keys()

func has_level(level_name: String) -> bool:
	return levels.has(level_name)
