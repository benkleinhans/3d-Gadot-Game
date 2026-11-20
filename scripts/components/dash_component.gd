class_name DashComponent
extends Node

signal dash_started(is_air_dash: bool)
signal dash_finished

@export var dash_speed := 19.0
@export var dash_duration := 0.22
@export var dash_cooldown := 1.0
@export_range(0, 5) var max_air_dashes := 1
@export var use_gravity_during_dash := false

var body: CharacterBody3D
var movement: MovementComponent
var cooldown_left := 0.0
var dash_left := 0.0
var air_dashes_left := 1
var dash_direction := Vector3.ZERO
var is_dashing := false
var is_air_dashing := false

func initialize(character: CharacterBody3D, mover: MovementComponent) -> void:
	body = character
	movement = mover
	air_dashes_left = max_air_dashes

func try_dash(input_dir: Vector2) -> bool:
	if body == null or is_dashing or cooldown_left > 0.0:
		return false
	var airborne := not body.is_on_floor()
	if airborne and air_dashes_left <= 0:
		return false
	var direction := movement.get_camera_relative_direction(input_dir) if movement else Vector3.ZERO
	if direction.length_squared() < 0.01:
		direction = -body.global_basis.z
	if airborne:
		air_dashes_left -= 1
	is_air_dashing = airborne
	is_dashing = true
	dash_left = dash_duration
	cooldown_left = dash_cooldown
	dash_direction = direction.normalized()
	body.velocity = dash_direction * dash_speed
	dash_started.emit(airborne)
	return true

func tick(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if body == null:
		return
	if body.is_on_floor():
		air_dashes_left = max_air_dashes
	if not is_dashing:
		return
	dash_left -= delta
	body.velocity.x = dash_direction.x * dash_speed
	body.velocity.z = dash_direction.z * dash_speed
	if not use_gravity_during_dash:
		body.velocity.y = dash_direction.y * dash_speed
	if dash_left <= 0.0:
		is_dashing = false
		is_air_dashing = false
		dash_finished.emit()
