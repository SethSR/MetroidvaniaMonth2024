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

@export var JUMP_VELOCITY: float = 280.0
@export var JUMP_GRAVITY: float = 980.0
@export var JUMP_FORCE_DURATION: float = 0.19

@export var GRAPPLE_LENGTH: float = 80.0
@export var GRAPPLE_MAX_SPEED: float = 20.0
@export var GRAPPLE_ACCELERATION: float = 300
@export var GRAPPLE_WOBBLE_LENGTH: float = 1.5

@export var EXCESS_SPEED_FRICTION: float = 3.0

var movement_state: MovementState = MovementState.FALLING
var input_vector: Vector2 = Vector2.ZERO
var wants_jump: bool = false
var released_jump: bool = false
var wants_dash: bool = false
var wants_grapple: bool = false

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

var coyote_timer: float = 0.0
var facing_direction: Direction = Direction.RIGHT


@onready var animation: AnimatedSprite2D = $PlayerSprite
@onready var grapple_vfx: Sprite2D = $GrappleVfx

func ready() -> void:
	dash_timer = 0.0
	jump_timer = 0.0
	coyote_timer = 0.0
	dash_charges = get_max_dash_charges()
	jump_charges = get_max_jump_charges()
	movement_state = MovementState.FALLING

#todo: get from unlocks system
func get_max_dash_charges() -> int:
	return 1

func get_max_jump_charges() -> int:
	return 1

func reset_inputs() -> void:
	wants_jump = false
	released_jump = false
	wants_dash = false
	wants_grapple = false

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

func update_debug_label() -> void:
	var label: Label = $Label
	label.text = "input_vector.x = " + str(input_vector.x) + "\nmove_left = " + str(Input.is_action_pressed("move_left")) + "\nmove_right = " + str(Input.is_action_pressed("move_right"))

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
		return true
	else:
		return false

func try_transition_to_dash() -> bool:
	if wants_dash and dash_charges > 0 and abs(input_vector.x) > 0.0:
		movement_state = MovementState.DASHING
		dash_charges -= 1
		dash_timer = DASH_DURATION
		velocity.x = DASH_SPEED * input_vector.x
		velocity.y = 0.0
		dash_current_direction = input_vector.x
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
	if grapple_current_length > 0:
		movement_state = MovementState.GRAPPLE
		dash_charges = get_max_dash_charges()
		jump_charges = get_max_jump_charges()
		return true
	else:
		return false

func end_grapple_state() -> void:
	grapple_current_length = 0.0
	grapple_vfx.visible = false
	grapple_wobble_tween.kill()

func try_state_transitions() -> void:
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
		apply_friction(WALKING_FRICTION * 1.8) # faster turnaround

	if abs(velocity.x) > WALKING_MAX_SPEED:
		apply_friction(EXCESS_SPEED_FRICTION)

	apply_acceleration(delta, WALKING_MAX_SPEED, WALKING_ACCELERATION)
	#todo: coyote time

#todo
func physics_dashing(delta: float) -> void:
	apply_friction(DASH_FRICTION)
	if not is_on_floor():
		apply_gravity(delta, DASH_GRAVITY)

#todo
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
	pass

#todo
func physics_stunned(_delta: float) -> void:
	pass

#todo
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

#todo:
func update_animations(_delta: float) -> void:
	if abs(velocity.x) > 0 and abs(input_vector.x) > 0.0:
		animation.play("walk")
	else:
		animation.play("idle")

	var percent_max_speed: float = abs(velocity.x) / WALKING_MAX_SPEED #todo: this only applies to walking
	animation.speed_scale = clamp(lerp(0.0, 1.0, percent_max_speed), 0.0, 1.0)
	animation.flip_h = false if is_facing_right() else true

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


#todo:
func update_sounds() -> void:
	return

func update_coyote_time(was_on_floor: bool, is_now_on_floor: bool) -> void:
	if movement_state != MovementState.WALKING:
		coyote_timer = 0.0
		return

	if was_on_floor == true and is_now_on_floor == false:
		coyote_timer = WALKING_COYOTE_TIME_DURATION

func check_grapple_raycast() -> void:
	var raycast_target: Vector2 = position
	raycast_target.x = raycast_target.x + GRAPPLE_LENGTH if is_facing_right() else raycast_target.x - GRAPPLE_LENGTH
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(position, raycast_target, 2)
	query.exclude = [self]
	var result: Dictionary = space_state.intersect_ray(query)

	if !result.is_empty():
		var collider: StaticBody2D = result.get("collider")
		grapple_anchor_point = collider.position
		grapple_current_length = abs(position.x - grapple_anchor_point.x)
		grapple_wobble_y = position.y
		grapple_wobble_timer = GRAPPLE_WOBBLE_LENGTH
		grapple_direction = facing_direction


		grapple_wobble_tween = create_tween()
		grapple_wobble_tween.tween_property(self, "grapple_wobble_y", grapple_anchor_point.y, GRAPPLE_WOBBLE_LENGTH).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()
	update_velocity(delta)
	@warning_ignore("return_value_discarded")
	move_and_slide()

	update_coyote_time(was_on_floor, is_on_floor())

	if wants_grapple and movement_state != MovementState.GRAPPLE:
		check_grapple_raycast()

	try_state_transitions()
	reset_inputs()

	update_timers(delta)
	update_animations(delta)
	update_sounds()

