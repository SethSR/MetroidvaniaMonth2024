extends Area2D

class_name Pickup_Unlock

@export var unlock: Enums.UnlockType
@export var unlock_texture: Texture

func _ready() -> void:
	var texture: Sprite2D = $Sprite2D as Sprite2D
	texture.texture = unlock_texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	print("unlock entered")
	var player: Player = body as Player
	if player != null:
		player.on_pickup(unlock)
	queue_free()