extends CharacterBody3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var weapon: StaticBody3D = $Weapon
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $"MeshInstance3D"

const APPROX_ZERO: float = 0.001
const MIN_LERP: float = 0.01
const MAX_LERP: float = 0.99

const SPEED: float = 10.0
const FRICTION: float = 8.0

const JUMP_VELOCITY: float = 5.0
const VELOCITY_CHANGE: float = 5.0

const SPRINT_VELOCITY: float = 7.0
const SPRINT_ACCEL: float = 17.0
const ROLL_HITBOX_HEIGHT: float = 1.0

const CAM_SENS: float = 0.005

var collision_shape_max_height: float
var sprinting: bool = false
var sprint_boost: Vector3 = Vector3.ZERO
var last_movement: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	collision_shape_max_height = collision_shape_3d.shape.height

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("strafe_left", "strafe_right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if not sprinting:
		if direction:
			velocity.x = lerp(velocity.x, direction.x * SPEED, clamp(VELOCITY_CHANGE * delta, MIN_LERP, MAX_LERP))
			velocity.z = lerp(velocity.z, direction.z * SPEED, clamp(VELOCITY_CHANGE * delta, MIN_LERP, MAX_LERP))
		elif is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, clamp(FRICTION * delta, MIN_LERP, MAX_LERP))
			velocity.z = lerp(velocity.z, 0.0, clamp(FRICTION * delta, MIN_LERP, MAX_LERP))
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if not sprinting:
		if Input.is_action_just_pressed("left_shift"):
			sprinting = true
			sprint_boost = -global_transform.basis.z.normalized() * SPRINT_VELOCITY
		elif collision_shape_3d.shape.height < collision_shape_max_height:
			collision_shape_3d.shape.height = lerp(collision_shape_3d.shape.height, collision_shape_max_height, clamp(SPRINT_ACCEL * delta, MIN_LERP, MAX_LERP))
			if (collision_shape_3d.shape.height + APPROX_ZERO) >= collision_shape_max_height:
				collision_shape_3d.shape.height = collision_shape_max_height
	
	if sprinting:
		sprint_boost = sprint_boost.lerp(Vector3.ZERO, SPRINT_ACCEL * delta)
		
		var new_collision_height = lerp(collision_shape_3d.shape.height, ROLL_HITBOX_HEIGHT, clamp(SPRINT_ACCEL * delta, MIN_LERP, MAX_LERP))
		global_position.y -= collision_shape_3d.shape.height - new_collision_height
		collision_shape_3d.shape.height = new_collision_height
		
		velocity += sprint_boost
		if sprint_boost.x <= APPROX_ZERO and sprint_boost.x >= -APPROX_ZERO and sprint_boost.z <= APPROX_ZERO and sprint_boost.z >= -APPROX_ZERO:
			sprinting = false
			sprint_boost = Vector3.ZERO
	
	if velocity.x <= APPROX_ZERO and velocity.x >= -APPROX_ZERO:
		velocity.x = 0.0
	if velocity.z <= APPROX_ZERO and velocity.z >= -APPROX_ZERO:
		velocity.z = 0.0
	
	print(collision_shape_3d.shape.height)
	mesh_instance_3d.mesh.height = collision_shape_3d.shape.height
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * CAM_SENS
		spring_arm.rotation.x -= event.relative.y * CAM_SENS
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/3)
		
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("left_click"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
		else:
			weapon.attack()
