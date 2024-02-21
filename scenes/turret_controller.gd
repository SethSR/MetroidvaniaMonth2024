extends Node

func _on_turret_shoot(bullet: Bullet, direction: Vector2, location: Vector2) -> void:
	bullet.direction = direction
	bullet.position = location
	add_child(bullet)
