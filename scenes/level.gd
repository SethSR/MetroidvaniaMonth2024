extends Node2D

class_name Level

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")

var doors: Dictionary = {}

func setup() -> void:
	for child: Node in get_children():
		if child is Door:
			var door: Door = child as Door
			doors[door.door_link] = door

func _on_turret_shoot(lifetime: float, direction: Vector2, location: Vector2, speed: float, polarity: Enums.Polarity) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()

	bullet.lifetime = lifetime
	bullet.speed = speed
	bullet.direction = direction
	bullet.position = location
	bullet.polarity = polarity
	bullet.modulate = Color.RED if polarity == Enums.Polarity.RED else Color.BLUE

	add_child(bullet)
