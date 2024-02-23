class_name PlayerProgression
extends Object

var unlock_progression: Dictionary = { }

func _init() -> void:
	populate_unlocks()

func populate_unlocks() -> void:
	for unlock_type: Enums.UnlockType in Enums.UnlockType.values():
		unlock_progression[unlock_type] = false

func has_unlock(unlock_type: Enums.UnlockType) -> bool:
	return unlock_progression.get(unlock_type, false)

func unlock(unlock_type: Enums.UnlockType) -> void:
	unlock_progression[unlock_type] = true
	print("Unlocked [", str(unlock_type), "]")

func debug_unlock_all() -> void:
	for unlock_type: Enums.UnlockType in unlock_progression.keys():
		unlock_progression[unlock_type] = true


