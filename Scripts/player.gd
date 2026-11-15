
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.003

@onready var camera_pivot: Node3D = $CameraPivot



func _ready() -> void:
	if is_multiplayer_authority():
		$CameraPivot/SpringArm3D/Camera3D.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		$CameraPivot/SpringArm3D/Camera3D.current = false



func _unhandled_input(event: InputEvent) -> void:
	
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -1.2, 0.7)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Keep your existing movement code below.

	# Apply gravity when the player is in the air.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump when standing on the ground.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Determine movement speed.
	var speed: float = walk_speed
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed

	# Read WASD input.
	var input_dir: Vector2 = Input.get_vector(
		"left",
		"right",
		"forward",
		"backwards"
	)

	# Move relative to the player's rotation.
	var direction: Vector3 = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
