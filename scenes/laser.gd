extends StaticBody2D

class_name Laser

enum Mode {
	Startup,
	CycleFiring,
	CycleResting,
}

const BULLET_LASER: PackedScene = preload("res://scenes/bullet_laser.tscn")

@export var duration_delay: float = -1
# NOTE - srenshaw - I'm not a huge fan of doing paired values this way, but
#  I don't know of an easier way to do this, and I don't want to spend the
#  time to look through docs and videos to figure it GDscript classes at the
#  moment.
@export var duration_cooldown: Array[Vector2] = [Vector2(1.0, 1.0)]
@export var laser_polarity: Enums.Polarity = Enums.Polarity.RED
@export var laser_volume: float = 0

@onready var sfx_loop: AudioStreamPlayer2D = $FadeInLoop
@onready var timer: Timer = $Timer
@onready var bullets: Node = $Bullets
@onready var ray: RayCast2D = $RayCast2D

var mode: Mode = Mode.Startup
var cooldown_index: int = -1
var is_active: bool = false
var num_tiles: int = 0

func _ready() -> void:
	assert(duration_delay != 0, get_parent().name + "::" + name + "::duration_delay cannot be 0")
	for cd: Vector2 in duration_cooldown:
		assert(cd.y >= 0.25, get_parent().name + "::" + name + " must have rest timers (duration_cooldown.y) above 0.25")
		sfx_loop.volume_db = laser_volume
	if duration_delay <= 0:
		timer.start(0.01)
	else:
		timer.start(duration_delay)

func _physics_process(_delta: float) -> void:
	if ray == null: return
	var point: Vector2 = ray.get_collision_point()
	if point.length_squared() <= 0: return
	var distance: float = global_position.distance_to(point)
	@warning_ignore("narrowing_conversion")
	num_tiles = (distance - 8) / 16
	assert(num_tiles > 0, "Unable to calculate laser's firing line")
	ray.queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		is_active = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		is_active = false

func _on_timer_timeout() -> void:
	match mode:
		Mode.Startup, Mode.CycleResting:
			cooldown_index = (cooldown_index + 1) % duration_cooldown.size()
			mode = Mode.CycleFiring
			if is_active:
				fire()
			if duration_cooldown[cooldown_index].x > 0:
				timer.start(duration_cooldown[cooldown_index].x)
			else:
				timer.paused = true
		Mode.CycleFiring:
			mode = Mode.CycleResting
			if is_active or bullets.get_child_count() > 0:
				rest()
			timer.start(duration_cooldown[cooldown_index].y)

func fire() -> void:
	sfx_loop.play()
	for i: int in range(num_tiles):
		var bullet: BulletLaser = BULLET_LASER.instantiate()
		bullet.position = Vector2(0, -16 * (i + 1))
		bullet.polarity = laser_polarity
		bullets.add_child(bullet)

func rest() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(sfx_loop, "volume_db", -60, 0.2)
	tween.tween_callback(func() -> void:
		sfx_loop.stop()
		sfx_loop.volume_db = laser_volume)
	for child: Node in bullets.get_children():
		(child as BulletLaser).deactivate()
