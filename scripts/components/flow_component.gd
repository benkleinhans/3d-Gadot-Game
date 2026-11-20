class_name FlowComponent
extends Node

signal flow_started
signal flow_ended

@export var can_flow := true
@export var activation_hold_seconds := 5.0
@export var flow_speed_multiplier := 3.0
@export var vertical_hover_height := 0.9
@export var hover_strength := 8.0
@export var turn_speed := 2.2

var body: CharacterBody3D
var movement: MovementComponent
var holding := false
var hold_time := 0.0
var flowing := false

func initialize(character: CharacterBody3D, mover: MovementComponent) -> void:
	body = character
	movement = mover

func set_hold_active(active: bool) -> void:
	if not can_flow or flowing:
		holding = false
		return
	if active and not holding:
		holding = true
		hold_time = 0.0
	elif not active:
		holding = false
		hold_time = 0.0

func tick(delta: float) -> void:
	if not can_flow or flowing or not holding:
		return
	hold_time += delta
	if hold_time >= activation_hold_seconds:
		enable_flow()

func enable_flow() -> void:
	if not can_flow or flowing:
		return
	flowing = true
	holding = false
	hold_time = 0.0
	if body:
		body.velocity.y = 0.0
	flow_started.emit()

func disable_flow() -> void:
	if not flowing:
		return
	flowing = false
	if body:
		body.velocity.y = 0.0
	flow_ended.emit()

func apply_flow(input_dir: Vector2, delta: float) -> void:
	if not flowing or body == null:
		return
	var turn := input_dir.x
	body.rotate_y(-turn * turn_speed * delta)
	var forward := -body.global_basis.z
	body.velocity.x = forward.x * movement.walk_speed * flow_speed_multiplier
	body.velocity.z = forward.z * movement.walk_speed * flow_speed_multiplier
	var target_y := vertical_hover_height
	body.velocity.y = clampf((target_y - body.position.y) * hover_strength, -3.0, 3.0)
