extends Node2D

class_name Level

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")

var doors: Array[Door] = []

func setup() -> void:
	for child: Node in get_children():
		if child is Door:
			doors.push_back(child as Door)

func _on_turret_shoot(lifetime: float, direction: Vector2, location: Vector2, speed: float) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()

	bullet.lifetime = lifetime
	bullet.speed = speed
	bullet.direction = direction
	bullet.position = location

	add_child(bullet)
