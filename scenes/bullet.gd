extends StaticBody2D

class_name Bullet

@export var lifetime: float = 3.0
@export var knockback: int = 100
@export var speed: float = 80.0
@export var direction: Vector2 = Vector2.ZERO

var life_timer: float = lifetime

func _process(delta: float) -> void:
	life_timer -= delta
	if life_timer < 0:
		queue_free()

func _physics_process(delta: float) -> void:
	var coll: KinematicCollision2D = move_and_collide(speed * direction.normalized() * delta)
	if coll != null:
		print("collision with: ", coll)
		var player: Player = coll.get_collider() as Player
		if player != null:
			player.receive_damage()
		queue_free()
