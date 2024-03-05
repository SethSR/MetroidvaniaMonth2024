extends StaticBody2D

class_name Door

signal on_entered_door(door: Door)
signal on_door_sensor_exited(door: Door)

@export var next_level: String
@export var door_link: DoorLink
@export_enum("Up", "Down", "Left", "Right") var connection: int = 0

@onready var collider: CollisionShape2D = $DoorCollider
@onready var sprite: Sprite2D = $Sprite2D
@onready var sensor: CollisionShape2D = $Area2D/DoorSensor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if next_level == null or next_level.is_empty():
		push_error(get_parent().name + "::" + name + " is missing a connected Level scene")
	assert(door_link != null, get_parent().name + "::" + name + " is missing a DoorLink")

	var level_db: LevelDB = get_node("/root/LevelDb")
	on_entered_door.connect(level_db._on_door_entered)
	on_door_sensor_exited.connect(level_db._on_door_sensor_exited)

	close()

func on_player_collision() -> void:
	on_entered_door.emit(self)
	open()

func open() -> void:
	collider.set_deferred("disabled", true)
	# TODO - srenshaw - This should change to an opening animation
	sprite.visible = false
	sensor.set_deferred("disabled", false)

func close() -> void:
	collider.set_deferred("disabled", false)
	# TODO - srenshaw - This should change to a closing animation
	sprite.visible = true
	sensor.set_deferred("disabled", true)

func _on_area_2d_body_exited(body: Node2D) -> void:
	print("Body Exited Sensor: ", body)
	if !body is Player:
		return

	on_door_sensor_exited.emit(self)
