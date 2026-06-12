extends Node

# pack_name (String) -> LevelPack
var _packs: Dictionary = {}

func _ready() -> void:
	# Register before any .lvl file is loaded.
	# Use load() for .lvl files - NEVER PRELOAD!
	ResourceLoader.add_resource_format_loader(LvlLoader.new(), true)

func load_pack(path: String) -> LevelPack:
	var res = load(path)
	if not res is LevelPack:
		push_error("LevelManager: '%s' did not produce a LevelPack" % path)
		return null
	_packs[res.pack_name] = res
	return res

func get_level(pack_name: String, level_name: String) -> LevelSpec:
	var pack := _packs.get(pack_name, null) as LevelPack
	if pack == null:
		push_error("LevelManager: pack '%s' not loaded" % pack_name)
		return null
	var spec := pack.get_level(level_name)
	if spec == null:
		push_error("LevelManager: level '%s' not in pack '%s'" % [level_name, pack_name])
	return spec

func get_pack(pack_name: String) -> LevelPack:
	return _packs.get(pack_name, null)

func get_pack_names() -> Array:
	return _packs.keys()

func get_level_names(pack_name: String) -> Array:
	var pack := _packs.get(pack_name, null) as LevelPack
	return pack.get_level_names() if pack else []

func has_level(pack_name: String, level_name: String) -> bool:
	var pack := _packs.get(pack_name, null) as LevelPack
	return pack != null and pack.has_level(level_name)
