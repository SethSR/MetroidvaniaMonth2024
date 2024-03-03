extends Node

class_name LevelDB

var root_node: Node = null
var current_level: Level = null

func _ready() -> void:
	root_node = get_node("/root/Root")
	assert(root_node != null, "No Root node found")

	for child: Node in root_node.get_children():
		if child is Level:
			current_level = child as Level
			break
	assert(current_level != null, "No initial level found in scene tree")

	current_level.setup()
	for door: Door in current_level.doors:
		door.is_open = false

func _on_door_entered(door: Door) -> void:
	load_level(door)

func load_level(door: Door) -> void:
	var next_level: Level = door.NextLevel.instantiate()
	next_level.setup()

	for other_door: Door in next_level.doors:
		if other_door.door_link == door.door_link:
			door.is_open = true
			other_door.is_open = true
			root_node.add_child(next_level)
			next_level.position = door.global_position - other_door.position
			match door.connection:
				1: next_level.position.y -= 16
				2: next_level.position.y += 16
				3: next_level.position.x += 16
				4: next_level.position.x -= 16
			break
