extends StaticBody2D

class_name BulletLaser

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $Timer

enum State {
	Activating,
	Active,
	Inactive,
}

const LASER_SMALL: Rect2i = Rect2i( 80, 256, 16, 16)
const LASER_LARGE: Rect2i = Rect2i(128, 144, 16, 16)

var state: State = State.Activating
var saved_pos: Vector2 = Vector2.ZERO
var polarity: Enums.Polarity = Enums.Polarity.RED

func _ready() -> void:
	saved_pos = sprite.position
	match polarity:
		Enums.Polarity.RED:
			modulate = Color.RED
			collision_layer = 0x10
		Enums.Polarity.BLUE:
			modulate = Color.BLUE
			collision_layer = 0x20
		Enums.Polarity.NONE:
			collision_layer = 0x30

func _on_timer_timeout() -> void:
	match state:
		State.Activating:
			sprite.region_rect = LASER_SMALL
			sprite.position = Vector2.ZERO
			state = State.Active
		State.Active:
			sprite.region_rect = LASER_LARGE
			sprite.position.x = saved_pos.x + randf_range(-0.5, 0.5)
			sprite.position.y = saved_pos.y + randf_range(-0.5, 0.5)
			sprite.flip_h = randi_range(0, 1) == 0
		State.Inactive:
			queue_free()

func deactivate() -> void:
	state = State.Inactive
	sprite.region_rect = LASER_SMALL
	sprite.position = Vector2.ZERO
	timer.start()
