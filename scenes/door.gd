extends StaticBody2D

class_name Door

signal on_entered_door(door: Door)
signal on_door_sensor_exited(door: Door)

@export var next_level: String
@export var door_link: DoorLink
@export_enum("Up", "Down", "Left", "Right") var connection: int = 0

@onready var collider: CollisionShape2D = $DoorCollider
@onready var sprites: Array[Sprite2D] = [$Sprite2D, $Sprite2D2, $Sprite2D3, $Sprite2D4]
@onready var sensor: CollisionShape2D = $Area2D/DoorSensor

var timer: float = 0.0
var is_opening: bool = false
var is_closing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if next_level == null or next_level.is_empty():
		push_error(get_parent().name + "::" + name + " is missing a connected Level scene")
	assert(door_link != null, get_parent().name + "::" + name + " is missing a DoorLink")

	var level_db: LevelDB = get_node("/root/LevelDb")
	on_entered_door.connect(level_db._on_door_entered)
	on_door_sensor_exited.connect(level_db._on_door_sensor_exited)

	set_open(false)
	for sprite: Sprite2D in sprites:
		sprite.visible = true

func _process(delta: float) -> void:
	if is_opening:
		timer += delta
		sprites[3].visible = timer <= 0.1
		sprites[2].visible = timer <= 0.2
		sprites[1].visible = timer <= 0.3
		sprites[0].visible = timer <= 0.4
		if timer > 0.4:
			set_open(true)
			is_opening = false
			timer = 0.0
	elif is_closing:
		timer += delta
		sprites[0].visible = timer > 0.1
		sprites[1].visible = timer > 0.2
		sprites[2].visible = timer > 0.3
		sprites[3].visible = timer > 0.4
		if timer > 0.4:
			is_closing = false
			timer = 0.0

func open() -> void:
	is_opening = true

func close() -> void:
	is_closing = true
	set_open(false)

func set_open(is_open: bool) -> void:
	collider.set_deferred("disabled", is_open)
	sensor.set_deferred("disabled", !is_open)

func on_player_collision() -> void:
	on_entered_door.emit(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		on_door_sensor_exited.emit(self)
