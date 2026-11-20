
class_name MovementComponent
extends Node

## Controls camera-relative character movement.
## The Player CharacterBody3D and active Camera3D are assigned through
## initialize().

@export_group("Movement Speed")

## Base walking speed, before running or Flow multipliers.
@export var walk_speed := 5.5

## Multiplier applied while the run toggle is active.
@export var run_multiplier := 1.5

## Multiplier applied while Flow is active.
@export var flow_multiplier := 3.0

## Multiplier applied to movement while locked onto a target.
## Kept separate so combat movement can be tuned independently.
@export_range(0.1, 1.5, 0.05) var strafe_multiplier := 0.8


@export_group("Movement Response")

@export var can_move := true
@export var has_gravity := true
@export var acceleration := 22.0
@export var air_acceleration := 8.0
@export var rotation_speed := 12.0


var body: CharacterBody3D
var camera: Camera3D
var last_move_direction := Vector3.FORWARD


## Connects this component to the player and its camera.
func initialize(character: CharacterBody3D, view_camera: Camera3D) -> void:
	body = character
	camera = view_camera


## Converts input into a horizontal direction relative to the camera.
func get_camera_relative_direction(input_dir: Vector2) -> Vector3:
	if camera == null:
		return Vector3.ZERO

	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x

	# Ignore camera pitch so looking up or down doesn't affect ground movement.
	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()

	return (right * input_dir.x - forward * input_dir.y).normalized()


## Updates horizontal movement, speed modifiers, and character facing.
##
## face_move:
##   Whether the character should rotate toward the movement direction.
##
## strafing:
##   Whether the lock-on movement speed multiplier should be applied.
func update_movement(
	input_dir: Vector2,
	delta: float,
	running: bool,
	flowing: bool = false,
	face_move: bool = true,
	strafing: bool = false
) -> void:
	if body == null:
		return

	if not can_move:
		stop_horizontal(delta)
		return

	var direction := get_camera_relative_direction(input_dir)

	# Start with the base walking speed.
	var speed := walk_speed

	# Apply the appropriate movement modifiers.
	if running:
		speed *= run_multiplier

	if flowing:
		speed *= flow_multiplier

	if strafing:
		speed *= strafe_multiplier

	# Use stronger acceleration on the ground and softer control in the air.
	var accel := acceleration if body.is_on_floor() else air_acceleration
	var target := direction * speed * input_dir.length()

	body.velocity.x = move_toward(body.velocity.x, target.x, accel * delta)
	body.velocity.z = move_toward(body.velocity.z, target.z, accel * delta)

	if direction.length_squared() > 0.001:
		last_move_direction = direction

		# Don't rotate toward movement when lock-on or Flow controls facing.
		if face_move and not flowing:
			var target_yaw := atan2(-direction.x, -direction.z)
			body.rotation.y = lerp_angle(
				body.rotation.y,
				target_yaw,
				rotation_speed * delta
			)


## Applies the CharacterBody3D's configured gravity while airborne.
func apply_gravity(delta: float) -> void:
	if body == null or not has_gravity or body.is_on_floor():
		return

	body.velocity += body.get_gravity() * delta


## Gradually slows horizontal movement when movement is disabled.
func stop_horizontal(delta: float) -> void:
	if body:
		body.velocity.x = move_toward(body.velocity.x, 0.0, acceleration * delta)
		body.velocity.z = move_toward(body.velocity.z, 0.0, acceleration * delta)
