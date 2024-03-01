extends StaticBody2D

class_name Turret

## Remember to connect this signal to whatever parent node this is under.
## Preferably a TurretController.
signal shoot(lifetime: float, direction: Vector2, location: Vector2, speed: float)

enum Mode {
	Startup,
	Cycle,
}

enum Facing {
	Up,
	Down,
	Left,
	Right,
}

@export_group("Durations", "duration_")
@export var duration_delay: float = 0.0
@export var duration_cooldown: float = 0.2
@export_group("Bullet", "bullet_")
@export var bullet_speed: float = 80.0
@export var bullet_lifetime: float = 3.0
@export_group("Firing Lines")
@export_flags("N:16", "E:1", "W:256", "S:4096", "NE:4", "NW:64", "SW:1024", "SE:16384", "NNE:8", "NNW:32", "ENE:2", "ESE:32768", "WNW:128", "WSW:512", "SSW:2048", "SSE:8192")
var firing_lines: int = 0

@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var mode: Mode = Mode.Startup
var delay_timer: float = 0.0
var cooldown_timer: float = 0.0

func _ready() -> void:
	var parent: Node = get_parent()
	while !(parent is TurretController):
		parent = parent.get_parent()

	assert(parent != null, "Turrets must have a TurretController ancestor")

	var tc: TurretController = parent as TurretController
	shoot.connect(tc._on_turret_shoot)

func _process(delta: float) -> void:
	if mode == Mode.Startup:
		mode = process_startup(delta)

	if mode == Mode.Cycle and process_cycle(delta):
		for i: int in range(16):
			if (firing_lines >> i) & 1:
				shoot.emit(bullet_lifetime, Vector2.from_angle(i * -TAU/16), position, bullet_speed)
		sfx.play()

func process_startup(delta: float) -> Mode:
	delay_timer += delta
	if delay_timer < duration_delay:
		return Mode.Startup
	else:
		return Mode.Cycle

func process_cycle(delta: float) -> bool:
	cooldown_timer += delta
	if cooldown_timer < duration_cooldown:
		return false

	cooldown_timer -= duration_cooldown
	return true
