extends StaticBody2D

class_name Bullet

var lifetime: float = 3.0
@export var knockback: int = 100
var speed: float = 80.0
var direction: Vector2 = Vector2.ZERO

var life_timer: float = lifetime
@export var polarity: Enums.Polarity = Enums.Polarity.RED

func _process(delta: float) -> void:
	life_timer -= delta
	if life_timer < 0:
		queue_free()

func _physics_process(delta: float) -> void:
	var coll: KinematicCollision2D = move_and_collide(speed * direction.normalized() * delta)
	if coll == null:
		return

	queue_free()
	var player: Player = coll.get_collider() as Player
	if player != null:
		print("collision with: ", player)
		player.receive_damage(self)
