
class_name LookComponent
extends Node

@export var mouse_sensitivity := 0.002
@export var stick_sensitivity := 2.2
@export_range(-89.0, -1.0) var min_pitch_degrees := -75.0
@export_range(1.0, 89.0) var max_pitch_degrees := 75.0
@export var invert_y := false

var pivot: Node3D
var body: CharacterBody3D
var pitch := deg_to_rad(-8.0)
var yaw := 0.0

func initialize(character: CharacterBody3D, camera_pivot: Node3D) -> void:
	body = character
	pivot = camera_pivot
	yaw = body.rotation.y
	_apply_rotation()

func handle_mouse_motion(relative: Vector2) -> void:
	var y_sign := 1.0 if invert_y else -1.0

	yaw -= relative.x * mouse_sensitivity
	pitch += relative.y * mouse_sensitivity * y_sign

	_apply_rotation()

func handle_stick_look(axis: Vector2, delta: float) -> void:
	var y_sign := 1.0 if invert_y else -1.0

	yaw -= axis.x * stick_sensitivity * delta
	pitch += axis.y * stick_sensitivity * delta * y_sign

	_apply_rotation()

# Call this after the player has rotated.
func sync_camera_rotation() -> void:
	_apply_rotation()

func _apply_rotation() -> void:
	pitch = clampf(
		pitch,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)

	if pivot and body:
		pivot.rotation = Vector3(
			pitch,
			yaw - body.rotation.y,
			0.0
		)
