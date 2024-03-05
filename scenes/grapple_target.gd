extends StaticBody2D
class_name GrappleTarget

var is_grappled: bool = false
@export var flip_sprite: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sprite: Sprite2D = $Sprite2D
	sprite.flip_h = flip_sprite
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
