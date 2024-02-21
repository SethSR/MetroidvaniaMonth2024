extends StaticBody2D

class_name Turret

## Remember to connect this signal to whatever parent node this is under.
## Preferably a TurretController.
signal shoot(bullet: Bullet, direction: Vector2, location: Vector2)

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")

enum Mode {
	Simple,
	Rotating,
	Tracking,
}

enum Facing {
	Up,
	Down,
	Left,
	Right,
}

@export var cooldown_duration: float = 0.2
@export var firing_lines: Array = [ false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ]

var cooldown_timer: float = -1

func _process(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer >= 0:
		return

	cooldown_timer = cooldown_duration

	for i: int in range(firing_lines.size()):
		if firing_lines[i]:
			shoot.emit(BULLET_SCENE.instantiate(), Vector2.from_angle(i * -TAU/16), position)
