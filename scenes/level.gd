extends Node

class_name TurretController

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")

func _on_turret_shoot(lifetime: float, direction: Vector2, location: Vector2, speed: float) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()

	bullet.lifetime = lifetime
	bullet.speed = speed
	bullet.direction = direction
	bullet.position = location

	add_child(bullet)
