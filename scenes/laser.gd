extends StaticBody2D

class_name Laser

enum Mode {
	Startup,
	Cycle,
}

@export_group("Durations", "duration_")
@export var duration_delay: float = 0.0
@export var duration_cooldown: Array[float] = [1.0]
@export var duration_firing: Array[float] = [1.0]
@export_group("Laser", "laser_")
@export var laser_polarity: Enums.Polarity = Enums.Polarity.RED

@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var mode: Mode = Mode.Startup
var delay_timer: float = 0.0
var cooldown_timer: float = 0.0
var cooldown_index: int = 0
var is_firing: bool = false
var is_active: bool = false

func _process(delta: float) -> void:
	if mode == Mode.Startup:
		mode = process_startup(delta)

	if mode == Mode.Cycle and process_cycle(delta) and is_active:
		shoot()
		sfx.play()

func process_startup(delta: float) -> Mode:
	delay_timer += delta
	if delay_timer < duration_delay:
		return Mode.Startup
	else:
		return Mode.Cycle

func process_cycle(delta: float) -> bool:
	cooldown_timer += delta
	if cooldown_timer < duration_cooldown[cooldown_index]:
		return false

	cooldown_timer -= duration_cooldown[cooldown_index]
	cooldown_index = (cooldown_index + 1) % duration_cooldown.size()
	return true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		is_active = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		is_active = false

func shoot() -> void:
	pass
