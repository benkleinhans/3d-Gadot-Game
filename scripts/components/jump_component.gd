
class_name JumpComponent
extends Node

signal jump_started(is_double_jump: bool)
signal charge_changed(normalized_charge: float)
signal charge_released(charge: float)

@export var can_jump := true
@export var max_jumps := 2
@export var jump_velocity := 5.0
@export var max_charge_seconds := 2.0
@export var charged_jump_bonus := 9.0

@export_group("Fall Settings")
## Multiplies gravity while descending.
## 1.0 = normal gravity, 1.5 = 50% stronger gravity.
@export_range(1.0, 4.0, 0.1) var fall_gravity_multiplier := 1.5

var body: CharacterBody3D
var jumps_remaining := 2
var charging := false
var charge_time := 0.0
var enabled := true


func initialize(character: CharacterBody3D) -> void:
	body = character
	jumps_remaining = max_jumps


## Applies additional gravity while the character is falling.
## Normal gravity is still handled by MovementComponent.
func apply_fall_gravity(delta: float) -> void:
	if body == null or body.is_on_floor():
		return

	# Only increase gravity while descending, not during ascent.
	if body.velocity.y < 0.0:
		var extra_gravity := fall_gravity_multiplier - 1.0
		body.velocity.y += body.get_gravity().y * extra_gravity * delta


func reset_on_floor() -> void:
	if body and body.is_on_floor():
		jumps_remaining = max_jumps


func begin_charge() -> void:
	if not _can_start():
		return

	charging = true
	charge_time = 0.0


func update_charge(delta: float) -> void:
	if not charging:
		return

	charge_time = minf(charge_time + delta, max_charge_seconds)
	charge_changed.emit(get_charge_ratio())


func release_charge() -> void:
	if not charging:
		return

	charging = false
	var ratio := get_charge_ratio()
	charge_released.emit(ratio)
	_perform_jump(jump_velocity + charged_jump_bonus * ratio)


func quick_jump() -> void:
	if not _can_start():
		return

	_perform_jump(jump_velocity)


func get_charge_ratio() -> float:
	return clampf(charge_time / max_charge_seconds, 0.0, 1.0) if max_charge_seconds > 0.0 else 1.0


func cancel_charge() -> void:
	charging = false
	charge_time = 0.0


func _can_start() -> bool:
	return enabled and can_jump and body != null and jumps_remaining > 0


func _perform_jump(velocity_y: float) -> void:
	if not _can_start():
		return

	var double_jump := not body.is_on_floor()
	body.velocity.y = velocity_y
	jumps_remaining -= 1
	jump_started.emit(double_jump)
