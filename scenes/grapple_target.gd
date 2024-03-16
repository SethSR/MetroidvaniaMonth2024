extends StaticBody2D
class_name GrappleTarget

enum State {
	Idle,
	Mid,
	PowerHi,
	PowerLo,
}

@export var ANIM_DURATION: float = 0.1
@export var BLINK_DURATION: float = 0.1

@onready var sprite: Sprite2D = $Sprite2D

var state: State = State.Idle
var is_charging: bool = false
var color: Color = Color.BLACK
var timer: float = 0.0

func _ready() -> void:
	color = sprite.modulate

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta

	match state:
		State.Idle:
			sprite.frame = 2
			if is_charging and timer > ANIM_DURATION:
				change_state(State.Mid)
		State.Mid:
			sprite.frame = 1
			if timer > ANIM_DURATION:
				change_state(State.PowerHi if is_charging else State.Idle)
		State.PowerHi:
			sprite.frame = 0
			sprite.modulate = Color.WHITE
			if !is_charging:
				change_state(State.Mid)
				sprite.modulate = color
			elif timer > BLINK_DURATION:
				change_state(State.PowerLo)
				sprite.modulate = color
		State.PowerLo:
			if !is_charging:
				change_state(State.Mid)
			elif timer > BLINK_DURATION:
				change_state(State.PowerHi)

func on_grapple(is_grappled: bool) -> void:
	is_charging = is_grappled

func change_state(new_state: State) -> void:
	state = new_state
	timer = 0.0
