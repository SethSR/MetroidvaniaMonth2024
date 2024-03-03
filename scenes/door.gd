extends StaticBody2D

class_name Door

signal on_entered_door(door: Door)

@export var NextLevel: PackedScene
@export var door_link: DoorLink
@export_enum("Up", "Down", "Left", "Right") var connection: int = 0

@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var is_open: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if NextLevel == null:
		push_error(get_parent().name + "::" + name + " is missing a connected Level scene")
	assert(door_link != null, get_parent().name + "::" + name + " is missing a DoorLink")

	var level_db: LevelDB = get_node("/root/LevelDb")
	on_entered_door.connect(level_db._on_door_entered)

	check_state()

func on_player_collision() -> void:
	if !is_open:
		on_entered_door.emit(self)
	is_open = true
	check_state()

func check_state() -> void:
	if is_open:
		open()
	else:
		close()

func open() -> void:
	collider.disabled = true
	# TODO - srenshaw - This should change to an opening animation
	sprite.visible = false

func close() -> void:
	collider.disabled = false
	# TODO - srenshaw - This should change to a closing animation
	sprite.visible = true
