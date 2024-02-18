extends CharacterBody2D

enum MovementState {FALLING, WALKING, JUMPING, DASHING, GRAPPLE, STUNNED}

@export var WALKING_MAX_SPEED: float = 125.0
@export var WALKING_ACCELERATION: float = 220.0
@export var WALKING_FRICTION: float = 1.875

@export var AIR_MAX_HORIZONTAL_SPEED: float = 125.0
@export var AIR_HORIZONTAL_ACCELERATION: float = 200.0
@export var AIR_FRICTION: float = 1.5

@export var FALLING_TERMINAL_VELOCITY: float = 250.0
@export var FALLING_GRAVITY: float = 650

@export var DASH_DURATION: float = 0.10
@export var DASH_SPEED: float = 325.0
@export var DASH_GRAVITY: float = 50.0
@export var DASH_FRICTION: float = 0.8

@export var JUMP_VELOCITY: float = 240.0
@export var JUMP_GRAVITY: float = 400.0

@export var EXCESS_SPEED_FRICTION: float = 3.0

var movement_state: MovementState = MovementState.FALLING
var input_vector: Vector2 = Vector2.ZERO
var wants_jump: bool = false
var wants_dash: bool = false
var wants_grapple: bool = false

var dash_timer: float = 0.0
var dash_current_direction: float = 0.0
var dash_charges: int = 0
var jump_charges: int = 0

@onready var animation: AnimatedSprite2D = $PlayerSprite

func ready():
	dash_timer = 0
	dash_charges = get_max_dash_charges()
	jump_charges = get_max_jump_charges()
	movement_state = MovementState.FALLING

#todo: get from unlocks system
func get_max_dash_charges():
	return 1
	
func get_max_jump_charges():
	return 1
	
func process_input():
	input_vector = Vector2.ZERO
	wants_jump = false
	wants_dash = false
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_just_pressed("dash"):
		wants_dash = true
	if Input.is_action_just_pressed("jump"):
		wants_jump = true
	if Input.is_action_pressed("grapple"):
		wants_grapple = true
	
	# no need to normalize input_vector, since we only account for left and right. 
	# if we want multidirectional dash we probably still don't want to normalize tbh
	#input_vector = input_vector.normalized()
	
#################### state transitions
func try_transition_to_jump() -> bool:
	if wants_jump and jump_charges > 0:
		movement_state = MovementState.JUMPING
		jump_charges -= 1
		velocity.y = JUMP_VELOCITY * -1.0
		return true
	else:
		return false
		
func try_transition_to_dash() -> bool:
	if wants_dash and dash_charges > 0 and abs(input_vector.x) > 0:
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
	if not is_on_floor() and dash_timer == 0 and velocity.y >= 0:
		movement_state = MovementState.FALLING
		return true
	else:
		return false
		
func try_transition_to_walking() -> bool:
	if is_on_floor() and dash_timer == 0:
		movement_state = MovementState.WALKING
		dash_charges = get_max_dash_charges()
		jump_charges = get_max_jump_charges()
		velocity.y = 0.0
		return true
	else:
		return false
		
		
func try_state_transitions():
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
			elif try_transition_to_falling():
				return
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
			elif is_zero_approx(dash_timer):
				if try_transition_to_falling():
					return
				elif try_transition_to_walking():
					return
		MovementState.STUNNED:
			movement_state = MovementState.FALLING
		MovementState.GRAPPLE:
			movement_state = MovementState.FALLING	

#################### physics functions
func apply_gravity(delta: float, gravity: float):
	velocity.y = move_toward(velocity.y, FALLING_TERMINAL_VELOCITY, gravity * delta)

func apply_friction(friction: float):
	velocity.x = move_toward(velocity.x, 0, friction)

func apply_acceleration(delta: float, max_speed: float, acceleration: float):
	velocity.x = move_toward(velocity.x, input_vector.x * max_speed, acceleration * delta)


func physics_falling(delta: float):
	apply_gravity(delta, FALLING_GRAVITY)
	if is_equal_approx(input_vector.x, 0.0) or input_vector.x * velocity.x < 0:
		apply_friction(AIR_FRICTION) 
	if abs(velocity.x) > AIR_MAX_HORIZONTAL_SPEED:
		apply_friction(EXCESS_SPEED_FRICTION)
	apply_acceleration(delta, AIR_MAX_HORIZONTAL_SPEED, AIR_HORIZONTAL_ACCELERATION)

func physics_walking(delta: float):
	if is_equal_approx(input_vector.x, 0.0) or input_vector.x * velocity.x < 0:
		apply_friction(WALKING_FRICTION) 
	if abs(velocity.x) > WALKING_MAX_SPEED:
		apply_friction(EXCESS_SPEED_FRICTION)
	apply_acceleration(delta, WALKING_MAX_SPEED, WALKING_ACCELERATION)
	#todo: coyote time

#todo
func physics_dashing(delta: float):
	apply_friction(DASH_FRICTION)
	if not is_on_floor():
		apply_gravity(delta, DASH_GRAVITY)
	
#todo
func physics_jumping(delta: float):
	apply_gravity(delta, JUMP_GRAVITY)
	if is_equal_approx(input_vector.x, 0.0) or input_vector.x * velocity.x < 0:
		apply_friction(AIR_FRICTION) 
	if abs(velocity.x) > AIR_MAX_HORIZONTAL_SPEED:
		apply_friction(EXCESS_SPEED_FRICTION)
	apply_acceleration(delta, AIR_MAX_HORIZONTAL_SPEED, AIR_HORIZONTAL_ACCELERATION)
	pass

#todo
func physics_stunned(delta: float):
	pass
	
#todo
func physics_grapple(delta: float):
	pass
	
#todo:
func update_velocity(delta: float):
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

func update_timers(delta: float):
	if dash_timer > 0:
		dash_timer = clamp(dash_timer - delta, 0, 100000.0)
	
#todo:
func update_animations():
	if abs(velocity.x) > 0 and abs(input_vector.x) > 0:
		animation.play("walk")
	else:
		animation.play("idle")
	
	var percent_max_speed = abs(velocity.x) / WALKING_MAX_SPEED #todo: this only applies to walking
	animation.speed_scale = clamp(lerp(0.0, 1.0, percent_max_speed), 0.0, 1.0)
	animation.flip_h = input_vector.x < 0

#todo:
func update_sounds():
	return

func _physics_process(delta):
	process_input()
	
	try_state_transitions()
	update_velocity(delta)
	move_and_slide()
	
	update_timers(delta)
	update_animations()
	update_sounds()

