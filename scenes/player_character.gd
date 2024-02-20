extends CharacterBody2D

enum MovementState {FALLING, WALKING, JUMPING, DASHING, GRAPPLE, STUNNED}

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

@export var JUMP_VELOCITY: float = 200.0
@export var JUMP_GRAVITY: float = 580.0
@export var JUMP_FORCE_DURATION: float = 0.28

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

var coyote_timer: float = 0.0

@onready var animation: AnimatedSprite2D = $PlayerSprite

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

func process_input() -> void:
	wants_jump = false
	released_jump = false
	wants_dash = false

	input_vector.x = Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("dash"):
		wants_dash = true
	if Input.is_action_just_pressed("jump"):
		wants_jump = true
	if Input.is_action_just_released("jump"):
		released_jump = true
	if Input.is_action_pressed("grapple"):
		wants_grapple = true

func update_debug_label() -> void:
	var label: Label = $Label
	label.text = "input_vector.x = " + str(input_vector.x) + "\nmove_left = " + str(Input.is_action_pressed("move_left")) + "\nmove_right = " + str(Input.is_action_pressed("move_right"))

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


func try_state_transitions() -> void:
	match movement_state:
		MovementState.FALLING:
			if try_transition_to_jump():
				return
			elif try_transition_to_dash():
				return
			elif try_transition_to_walking():
				return
		MovementState.WALKING:
			if try_transition_to_jump():
				return
			elif try_transition_to_dash():
				return
			elif coyote_timer <= 0.0:
				try_transition_to_falling()
		MovementState.JUMPING:
			if try_transition_to_dash():
				return
			elif try_transition_to_jump():
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
		MovementState.STUNNED:
			movement_state = MovementState.FALLING
		MovementState.GRAPPLE:
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
func physics_grapple(_delta: float) -> void:
	pass

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

#todo:
func update_animations() -> void:
	if abs(velocity.x) > 0 and abs(input_vector.x) > 0.0:
		animation.play("walk")
	else:
		animation.play("idle")

	var percent_max_speed: float = abs(velocity.x) / WALKING_MAX_SPEED #todo: this only applies to walking
	animation.speed_scale = clamp(lerp(0.0, 1.0, percent_max_speed), 0.0, 1.0)
	animation.flip_h = input_vector.x < 0.0

#todo:
func update_sounds() -> void:
	return

func update_coyote_time(was_on_floor: bool, is_now_on_floor: bool) -> void:
	if movement_state != MovementState.WALKING:
		coyote_timer = 0.0
		return

	if was_on_floor == true and is_now_on_floor == false:
		coyote_timer = WALKING_COYOTE_TIME_DURATION

func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()
	update_velocity(delta)
	@warning_ignore("return_value_discarded")
	move_and_slide()

	update_coyote_time(was_on_floor, is_on_floor())

	try_state_transitions()

	update_timers(delta)
	update_animations()
	update_sounds()

