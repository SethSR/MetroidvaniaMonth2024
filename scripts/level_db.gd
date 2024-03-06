extends Node

class_name LevelDB

var root_node: Node = null
var current_level: Level = null

var loaded_levels: Dictionary = {}

func _ready() -> void:
	root_node = get_node("/root/Root")
	assert(root_node != null, "No Root node found")

	for child: Node in root_node.get_children():
		if child is Level:
			current_level = child as Level
			loaded_levels[current_level.scene_file_path] = current_level
			break
	assert(current_level != null, "No initial level found in scene tree")

	current_level.setup()

func _on_door_entered(door: Door) -> void:
	if loaded_levels.has(door.next_level):
		var next_level: Level = loaded_levels[door.next_level]
		var other_door: Door = next_level.doors[door.door_link]
		door.open()
		other_door.open()
	else:
		var next_level: Level = load_level(door.next_level)
		var other_door: Door = next_level.doors[door.door_link]
		door.open()
		other_door.open()

		next_level.position += door.global_position - other_door.global_position
		match door.connection:
			0: next_level.position.y -= 16
			1: next_level.position.y += 16
			2: next_level.position.x -= 16
			3: next_level.position.x += 16

func load_level(level_scene_path: String) -> Level:
	var next_level: Level = (load(level_scene_path) as PackedScene).instantiate()
	next_level.setup()
	loaded_levels[level_scene_path] = next_level
	root_node.add_child(next_level)
	next_level.owner = root_node
	return next_level

func _on_door_sensor_exited(door: Door) -> void:
	door.close()
	if loaded_levels.has(door.next_level):
		var other_level: Level = loaded_levels[door.next_level]
		var other_door: Door = other_level.doors[door.door_link]
		other_door.close()
