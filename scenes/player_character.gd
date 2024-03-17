extends CharacterBody2D

class_name Player

enum MovementState {FALLING, WALKING, JUMPING, DASHING, GRAPPLE, STUNNED}
enum Direction {LEFT, RIGHT}

@export var WALKING_MAX_SPEED: float = 125.0
@export var WALKING_ACCELERATION: float = 260.0
@export var WALKING_FRICTION: float = 1.875
@export var WALKING_COYOTE_TIME_DURATION: float = 0.06

@export var AIR_MAX_HORIZONTAL_SPEED: float = 125.0
@export var AIR_HORIZONTAL_ACCELERATION: float = 200.0
@export var AIR_FRICTION: float = 1.5

@export var FALLING_TERMINAL_VELOCITY: float = 400.0
@export var FALLING_GRAVITY: float = 680

@export var DASH_DURATION: float = 0.08
@export var DASH_SPEED: float = 310.0
@export var DASH_GRAVITY: float = 50.0
@export var DASH_FRICTION: float = 0.8
@export var DASH_SFX_VOLUME: float = -3.0

@export var JUMP_VELOCITY: float = 280.0
@export var JUMP_GRAVITY: float = 980.0
@export var JUMP_FORCE_DURATION: float = 0.19
@export var JUMP_SFX_VOLUME: float = 0.0

@export var GRAPPLE_LENGTH: float = 80.0
@export var GRAPPLE_MAX_SPEED: float = 60.0
@export var GRAPPLE_ACCELERATION: float = 300
@export var GRAPPLE_WOBBLE_LENGTH: float = 1.5
@export var GRAPPLE_TRACE_RADIUS: float = 6.0
@export var GRAPPLE_SFX_VOLUME: float = -6.0

@export var STUN_HORIZONTAL_KNOCKBACK: float = 140.0
@export var STUN_VERTICAL_KNOCKBACK: float = -90.0
@export var STUN_DURATION: float = 0.6

@export var SHIELD_DURATION: float = 1.0
@export var POLARITY_RED_TINT: Color = Color.ORANGE_RED
@export var POLARITY_BLUE_TINT: Color = Color.AQUA

@export var EXCESS_SPEED_FRICTION: float = 3.0

@export var UNLOCK_SFX_VOLUME: float = -3.0

var movement_state: MovementState = MovementState.FALLING
var input_vector: Vector2 = Vector2.ZERO
var wants_jump: bool = false
var released_jump: bool = false
var wants_dash: bool = false
var wants_grapple: bool = false
var stunned_this_frame: bool = false
var grappled_this_frame: bool = false
var wants_polarity_change: bool = false

var jump_timer: float = 0.0
var jump_charges: int = 0

var dash_timer: float = 0.0
var dash_current_direction: float = 0.0
var dash_charges: int = 0

var grapple_current_length: float = 0.0
var grapple_anchor_point: Vector2 = Vector2.ZERO
var grapple_wobble_timer: float = 0.0
var grapple_wobble_y: float = 0.0
var grapple_wobble_tween: Tween
var grapple_direction: Direction = Direction.RIGHT
var grapple_target: GrappleTarget = null

var stun_timer: float = 0.0
var polarity_timer: float = 0.0

var coyote_timer: float = 0.0
var facing_direction: Direction = Direction.RIGHT
var current_polarity: Enums.Polarity = Enums.Polarity.NONE

var progression: PlayerProgression = PlayerProgression.new()

@onready var animation: AnimatedSprite2D = $PlayerSprite
@onready var grapple_vfx: Sprite2D = $GrappleVfx
@onready var sfx_jump: AudioStreamPlayer2D = $Jump
@onready var sfx_grapple: AudioStreamPlayer2D = $Grapple
@onready var sfx_dash: AudioStreamPlayer2D = $Dash
@onready var sfx_unlock: AudioStreamPlayer2D = $Unlock
@onready var dash_icon: HBoxContainer = $Camera2D/CanvasLayer/GridContainer/Dash
@onready var grapple_icon: HBoxContainer = $Camera2D/CanvasLayer/GridContainer/Grapple
@onready var polarity_icon: HBoxContainer = $Camera2D/CanvasLayer/GridContainer/Polarity
@onready var unlock_ui: Dictionary = {
	Enums.UnlockType.DASH: dash_icon,
	Enums.UnlockType.GRAPPLE: grapple_icon,
	Enums.UnlockType.POLARITY_1: polarity_icon,
	Enums.UnlockType.POLARITY_2: polarity_icon,
}

func ready() -> void:
	dash_timer = 0.0
	jump_timer = 0.0
	coyote_timer = 0.0
	dash_charges = get_max_dash_charges()
	jump_charges = get_max_jump_charges()
	movement_state = MovementState.FALLING
	sfx_jump.volume_db = JUMP_SFX_VOLUME
	sfx_grapple.volume_db = GRAPPLE_SFX_VOLUME
	sfx_dash.volume_db = DASH_SFX_VOLUME
	sfx_unlock.volume_db = UNLOCK_SFX_VOLUME

func on_pickup(unlock: Enums.UnlockType) -> void:
	if !progression.has_unlock(unlock):
		progression.unlock(unlock)
		unlock_ui[unlock].visible = true
		sfx_unlock.play()
		if unlock == Enums.UnlockType.POLARITY_1:
			unlock_ui[unlock].modulate = Color.RED
		elif unlock == Enums.UnlockType.POLARITY_2:
			match current_polarity:
				Enums.Polarity.RED:
					unlock_ui[unlock].modulate = Color.BLUE
				Enums.Polarity.BLUE:
					unlock_ui[unlock].modulate = Color.RED
				Enums.Polarity.NONE:
					unlock_ui[unlock].modulate = Color.RED

		#todo: animation?

#todo: get from unlocks system
func get_max_dash_charges() -> int:
	return 1

func get_max_jump_charges() -> int:
	return 2 if progression.has_unlock(Enums.UnlockType.DOUBLE_JUMP) else 1

func reset_inputs() -> void:
	wants_jump = false
	released_jump = false
	wants_dash = false
	wants_grapple = false
	grappled_this_frame = false
	stunned_this_frame = false
	wants_polarity_change = false

func process_input() -> void:
	input_vector.x = Input.get_axis("move_left", "move_right")
	if input_vector.x < 0:
		facing_direction = Direction.LEFT
	elif input_vector.x > 0:
		facing_direction = Direction.RIGHT

	if Input.is_action_just_pressed("dash"):
		wants_dash = true
	if Input.is_action_just_pressed("jump"):
		wants_jump = true
	if Input.is_action_just_released("jump"):
		released_jump = true
	if Input.is_action_just_pressed("grapple"):
		wants_grapple = true
	if Input.is_action_just_pressed("switch_polarity"):
		wants_polarity_change = true

	if Input.is_action_just_pressed("debug_unlock_all"):
		progression.debug_unlock_all()
	if Input.is_action_just_pressed("debug_unlock_dash"):
		progression.unlock(Enums.UnlockType.DASH)
	if Input.is_action_just_pressed("debug_unlock_double_jump"):
		progression.unlock(Enums.UnlockType.DOUBLE_JUMP)
	if Input.is_action_just_pressed("debug_unlock_grapple"):
		progression.unlock(Enums.UnlockType.GRAPPLE)
	if Input.is_action_just_pressed("debug_unlock_polarity_1"):
		progression.unlock(Enums.UnlockType.POLARITY_1)
	if Input.is_action_just_pressed("debug_unlock_polarity_2"):
		progression.unlock(Enums.UnlockType.POLARITY_2)

func update_debug_label() -> void:
	var label: Label = $Label
	label.text = ""

func is_facing_right() -> bool:
	return facing_direction == Direction.RIGHT

# no need to normalize input_vector, since we only account for left and right.
# if we want multidirectional dash we probably still don't want to normalize tbh
#input_vector = input_vector.normalized()

func _process(_delta: float) -> void:
	process_input()
	update_debug_label()

#################### state transitions
func try_transition_to_jump() -> bool:
	if wants_jump and jump_charges > 0:
		movement_state = MovementState.JUMPING
		jump_charges -= 1
		jump_timer = JUMP_FORCE_DURATION
		velocity.y = JUMP_VELOCITY * -1.0
		sfx_jump.play()
		return true
	else:
		return false

func try_transition_to_dash() -> bool:
	if not progression.has_unlock(Enums.UnlockType.DASH):
		return false
	if wants_dash and dash_charges > 0 and abs(input_vector.x) > 0.0:
		movement_state = MovementState.DASHING
		dash_charges -= 1
		dash_timer = DASH_DURATION
		velocity.x = DASH_SPEED * input_vector.x
		velocity.y = 0.0
		dash_current_direction = input_vector.x
		sfx_dash.play()
		return true
	else:
		return false

func try_transition_to_falling() -> bool:
	if not is_on_floor() and dash_timer <= 0.0 and velocity.y >= 0.0:
		# consume a jump charge if we fall off
		if movement_state == MovementState.WALKING:
			jump_charges -= 1
		movement_state = MovementState.FALLING
		return true
	else:
		return false

func try_transition_to_walking() -> bool:
	if is_on_floor() and dash_timer <= 0.0:
		movement_state = MovementState.WALKING
		dash_charges = get_max_dash_charges()
		jump_charges = get_max_jump_charges()
		velocity.y = 0.0
		return true
	else:
		return false

func try_transition_to_grapple() -> bool:
	if not progression.has_unlock(Enums.UnlockType.GRAPPLE):
		return false
	if grappled_this_frame:
		movement_state = MovementState.GRAPPLE
		dash_charges = get_max_dash_charges()
		jump_charges = get_max_jump_charges()
		sfx_grapple.play()
		return true
	else:
		return false

func end_grapple_state() -> void:
	grapple_current_length = 0.0
	grapple_vfx.visible = false
	grapple_wobble_tween.kill()
	grapple_target.on_grapple(false)
	grapple_target = null
	var tween: Tween = create_tween()
	tween.tween_property(sfx_grapple, "volume_db", -60, 0.2)
	tween.tween_callback(func() -> void:
		sfx_grapple.stop()
		sfx_grapple.volume_db = GRAPPLE_SFX_VOLUME)

func try_state_transitions() -> void:
	if stunned_this_frame:
		if movement_state == MovementState.GRAPPLE:
			end_grapple_state()
		movement_state = MovementState.STUNNED
		return

	match movement_state:
		MovementState.FALLING:
			if try_transition_to_jump():
				return
			elif try_transition_to_dash():
				return
			elif try_transition_to_walking():
				return
			elif try_transition_to_grapple():
				return
		MovementState.WALKING:
			if try_transition_to_jump():
				return
			elif try_transition_to_dash():
				return
			elif try_transition_to_grapple():
				return
			elif coyote_timer <= 0.0:
				try_transition_to_falling()
		MovementState.JUMPING:
			if try_transition_to_dash():
				return
			elif try_transition_to_jump():
				return
			elif try_transition_to_grapple():
				return
			elif try_transition_to_falling():
				return
		MovementState.DASHING:
			if try_transition_to_jump():
				return
			elif dash_timer <= 0.0:
				if try_transition_to_falling():
					return
				elif try_transition_to_walking():
					return
			elif try_transition_to_grapple():
				return
		MovementState.STUNNED:
			if stun_timer <= 0.0:
				movement_state = MovementState.FALLING
		MovementState.GRAPPLE:
			if try_transition_to_jump():
				velocity.y = velocity.y * 0.8 # decrease jump height when coming out of grapple
				end_grapple_state()
			elif try_transition_to_dash():
				end_grapple_state()
			elif wants_grapple:
				end_grapple_state()
				movement_state = MovementState.FALLING

#################### physics functions
func apply_gravity(delta: float, gravity: float) -> void:
	velocity.y = move_toward(velocity.y, FALLING_TERMINAL_VELOCITY, gravity * delta)

func apply_friction(friction: float) -> void:
	velocity.x = move_toward(velocity.x, 0, friction)

func apply_acceleration(delta: float, max_speed: float, acceleration: float) -> void:
	velocity.x = move_toward(velocity.x, input_vector.x * max_speed, acceleration * delta)


func physics_falling(delta: float) -> void:
	apply_gravity(delta, FALLING_GRAVITY)
	if is_zero_approx(input_vector.x) or input_vector.x * velocity.x < 0.0:
		apply_friction(AIR_FRICTION)
	if abs(velocity.x) > AIR_MAX_HORIZONTAL_SPEED:
		apply_friction(EXCESS_SPEED_FRICTION)
	apply_acceleration(delta, AIR_MAX_HORIZONTAL_SPEED, AIR_HORIZONTAL_ACCELERATION)

func physics_walking(delta: float) -> void:
	if is_equal_approx(input_vector.x, 0.0):
		apply_friction(WALKING_FRICTION)
	elif input_vector.x * velocity.x < 0.0:
		apply_friction(WALKING_FRICTION * 4) # faster turnaround

	if abs(velocity.x) > WALKING_MAX_SPEED:
		apply_friction(EXCESS_SPEED_FRICTION)

	apply_acceleration(delta, WALKING_MAX_SPEED, WALKING_ACCELERATION)


func physics_dashing(delta: float) -> void:
	apply_friction(DASH_FRICTION)
	if not is_on_floor():
		apply_gravity(delta, DASH_GRAVITY)


func physics_jumping(delta: float) -> void:
	if released_jump:
		jump_timer = 0.0
	if jump_timer <= 0.0:
		apply_gravity(delta, JUMP_GRAVITY)
	if is_equal_approx(input_vector.x, 0.0) or input_vector.x * velocity.x < 0.0:
		apply_friction(AIR_FRICTION)
	if abs(velocity.x) > AIR_MAX_HORIZONTAL_SPEED:
		apply_friction(EXCESS_SPEED_FRICTION)
	apply_acceleration(delta, AIR_MAX_HORIZONTAL_SPEED, AIR_HORIZONTAL_ACCELERATION)

#todo
func physics_stunned(delta: float) -> void:
	apply_gravity(delta, FALLING_GRAVITY)
	apply_friction(AIR_FRICTION)

func physics_grapple(delta: float) -> void:
	velocity = Vector2.ZERO

	if grapple_current_length > GRAPPLE_LENGTH:
		grapple_current_length = GRAPPLE_LENGTH # fix for hitting the grapple point hitbox a bit further than the max length, since the hitbox is a bit further out than the anchor point

	if grapple_current_length <= GRAPPLE_LENGTH:
		var direction_modifier: float = -1.0 if grapple_direction == Direction.RIGHT else 1.0
		grapple_current_length = grapple_current_length + (GRAPPLE_MAX_SPEED * delta * input_vector.x * direction_modifier)
		grapple_current_length = clamp(grapple_current_length, 8.0, GRAPPLE_LENGTH)
		var grapple_offset: float = grapple_current_length * direction_modifier
		position.x = grapple_anchor_point.x + grapple_offset
		if grapple_wobble_tween.is_running():
			position.y = grapple_wobble_y

#todo:
func update_velocity(delta: float) -> void:
	match movement_state:
		MovementState.FALLING:
			physics_falling(delta)
		MovementState.WALKING:
			physics_walking(delta)
		MovementState.DASHING:
			physics_dashing(delta)
		MovementState.JUMPING:
			physics_jumping(delta)
		MovementState.STUNNED:
			physics_stunned(delta)
		MovementState.GRAPPLE:
			physics_grapple(delta)

func update_timers(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer = dash_timer - delta
	if jump_timer > 0.0:
		jump_timer = jump_timer - delta
	if coyote_timer > 0.0:
		coyote_timer = coyote_timer - delta
	if grapple_wobble_timer > 0.0:
		grapple_wobble_timer = grapple_wobble_timer - delta
	if stun_timer > 0.0:
		stun_timer = stun_timer - delta

func update_animations(_delta: float) -> void:
	if abs(velocity.x) > 0 and abs(input_vector.x) > 0.0:
		animation.play("walk")
	else:
		animation.play("idle")

	var percent_max_speed: float = abs(velocity.x) / WALKING_MAX_SPEED #todo: this only applies to walking
	animation.speed_scale = clamp(lerp(0.0, 1.0, percent_max_speed), 0.0, 1.0)
	animation.flip_h = !is_facing_right()

	if movement_state == MovementState.GRAPPLE:
		grapple_vfx.region_rect.size.x = grapple_current_length
		grapple_vfx.visible = true
		if grapple_direction == Direction.RIGHT:
			grapple_vfx.position.x = grapple_current_length / 2.0
			grapple_vfx.flip_h = false
		else:
			grapple_vfx.position.x = grapple_current_length / -2.0
			grapple_vfx.flip_h = true
		#todo: account for grapple wobble, keep beam fixed at anchor

func update_coyote_time(was_on_floor: bool, is_now_on_floor: bool) -> void:
	if movement_state != MovementState.WALKING:
		coyote_timer = 0.0
		return

	if was_on_floor and !is_now_on_floor:
		coyote_timer = WALKING_COYOTE_TIME_DURATION

func get_tile_global_position(tm: TileMap, cell: RID) -> Vector2:
	var coords: Vector2i = tm.get_coords_for_body_rid(cell)
	return tm.to_global(tm.map_to_local(coords))

func sort_raycast_results(a: Dictionary, b: Dictionary) -> bool:
	var ac: Node2D = a.get("collider")
	var bc: Node2D = b.get("collider")
	if bc == null:
		return true
	elif ac == null:
		return false
	else:
		var a_pos: Vector2 = get_tile_global_position(ac as TileMap, a.get("rid") as RID) if ac is TileMap else ac.global_position
		var b_pos: Vector2 = get_tile_global_position(bc as TileMap, b.get("rid") as RID) if bc is TileMap else bc.global_position
		if is_facing_right():
			return a_pos.x < b_pos.x
		else:
			return a_pos.x > b_pos.x

func check_grapple_raycast() -> void:
	var raycast_target: Vector2 = global_position
	raycast_target.x += GRAPPLE_LENGTH if is_facing_right() else -GRAPPLE_LENGTH
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var trace_shape: CircleShape2D = CircleShape2D.new()
	trace_shape.radius = GRAPPLE_TRACE_RADIUS

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = trace_shape
	query.motion = raycast_target - global_position
	# NOTE - The mask collides with walls and grapple points, we'll ignore the
	#  walls later
	query.collision_mask = 3
	query.exclude = [self]
	query.transform = Transform2D(0.0, global_position)

	var result_arr: Array[Dictionary] = space_state.intersect_shape(query, 6)
	if result_arr.size() <= 0:
		return

	var target_heights: Array = result_arr.filter(func(a: Dictionary) -> bool:
		var ac: Node2D = a.get("collider")
		return ac != null and ac is GrappleTarget
	).map(func(a: Dictionary) -> float: return (a.get("collider") as Node2D).global_position.y)

	result_arr = result_arr.filter(func(a: Dictionary) -> bool:
		var ac: Node2D = a.get("collider")
		if ac == null:
			return false
		var height: float = get_tile_global_position(ac as TileMap, a.get("rid") as RID).y if ac is TileMap else ac.global_position.y
		return target_heights.any(func(t_height: float) -> bool: return t_height == height)
	)

	# Check if there's anything left
	if result_arr.size() <= 0:
		return

	# Sort the results so the first item is always the nearest tile or object
	result_arr.sort_custom(sort_raycast_results)

	var node: Node = result_arr[0].get("collider")
	if node is GrappleTarget:
		grapple_target = node as GrappleTarget
	else:
		return

	if grapple_target.rotation_degrees > 0:
		grapple_direction = Direction.LEFT
	elif grapple_target.rotation_degrees < 0:
		grapple_direction = Direction.RIGHT
	grapple_target.on_grapple(true)
	grapple_anchor_point = grapple_target.global_position
	grapple_current_length = abs(global_position.x - grapple_anchor_point.x)
	grappled_this_frame = true

	grapple_wobble_timer = GRAPPLE_WOBBLE_LENGTH
	grapple_wobble_y = global_position.y
	grapple_wobble_tween = create_tween()
	grapple_wobble_tween.tween_property(self, "grapple_wobble_y", grapple_anchor_point.y, GRAPPLE_WOBBLE_LENGTH).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func receive_damage(polarity: Enums.Polarity, direction: Vector2) -> void:
	if polarity == current_polarity:
		return
	stunned_this_frame = true
	velocity.x = -1.0 * STUN_HORIZONTAL_KNOCKBACK if direction.x < 0 else STUN_HORIZONTAL_KNOCKBACK
	velocity.y = -1.0 * STUN_VERTICAL_KNOCKBACK if direction.y > 0 else STUN_VERTICAL_KNOCKBACK
	stun_timer = STUN_DURATION

func update_polarity(delta: float) -> void:
	if progression.has_unlock(Enums.UnlockType.POLARITY_2) and wants_polarity_change:
		if current_polarity == Enums.Polarity.BLUE:
			current_polarity = Enums.Polarity.RED
			animation.modulate = POLARITY_RED_TINT
			collision_mask = 0b0010_1001
			polarity_icon.modulate = Color.BLUE
		else:
			current_polarity = Enums.Polarity.BLUE
			animation.modulate = POLARITY_BLUE_TINT
			collision_mask = 0b0001_1001
			polarity_icon.modulate = Color.RED

	elif progression.has_unlock(Enums.UnlockType.POLARITY_1):
		if polarity_timer > 0.0:
			polarity_timer = polarity_timer - delta
			if polarity_timer <= 0.0:
				current_polarity = Enums.Polarity.NONE
				animation.modulate = Color.WHITE
				collision_mask = 0b0011_1001
		elif current_polarity == Enums.Polarity.NONE and wants_polarity_change:
			current_polarity = Enums.Polarity.RED
			animation.modulate = POLARITY_RED_TINT
			polarity_timer = SHIELD_DURATION
			collision_mask = 0b0010_1001

func _physics_process(delta: float) -> void:
	update_polarity(delta)

	var was_on_floor: bool = is_on_floor()
	update_velocity(delta)
	@warning_ignore("return_value_discarded")
	move_and_slide()

	update_coyote_time(was_on_floor, is_on_floor())

	if progression.has_unlock(Enums.UnlockType.GRAPPLE) and wants_grapple and movement_state != MovementState.GRAPPLE:
		check_grapple_raycast()

	try_state_transitions()
	reset_inputs()

	update_timers(delta)
	update_animations(delta)

	for i: int in get_slide_collision_count():
		var coll: KinematicCollision2D = get_slide_collision(i)
		if coll == null: continue

		var coll_obj: Node = coll.get_collider()
		if coll_obj is Door:
			var door: Door = coll_obj as Door;
			door.on_player_collision()
		elif coll_obj is BulletLaser:
			var b_laser: BulletLaser = coll_obj as BulletLaser
			var dir: Vector2 = b_laser.global_position.direction_to(global_position)
			receive_damage(b_laser.polarity, dir)
