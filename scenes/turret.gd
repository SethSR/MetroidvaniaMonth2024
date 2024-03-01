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

var mode: Mode = Mode.Startup
var delay_timer: float = 0.0
var cooldown_timer: float = 0.0

func _process(delta: float) -> void:
	if mode == Mode.Startup:
		mode = Turret.process_startup(delta, delay_timer, duration_delay)

	if mode == Mode.Cycle and Turret.process_cycle(delta, cooldown_timer, duration_cooldown):
		for i: int in range(16):
			if (firing_lines >> i) & 1:
				shoot.emit(bullet_lifetime, Vector2.from_angle(i * -TAU/16), position, bullet_speed)

static func process_startup(delta: float, timer: float, duration: float) -> Mode:
	timer += delta
	if timer < duration:
		return Mode.Startup
	else:
		return Mode.Cycle

static func process_cycle(delta: float, timer: float, duration: float) -> bool:
	timer += delta
	if timer < duration:
		return false

	timer -= duration
	return true
