class_name EnemyMovementComponent
extends Node

@export var move_speed := 3.0
@export var acceleration := 10.0
var body: CharacterBody3D
var target: Node3D

func initialize(owner_body: CharacterBody3D) -> void:
	body = owner_body

func chase(delta: float) -> void:
	if body == null or not is_instance_valid(target):
		return
	var direction := target.global_position - body.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.1:
		return
	direction = direction.normalized()
	body.velocity.x = move_toward(body.velocity.x, direction.x * move_speed, acceleration * delta)
	body.velocity.z = move_toward(body.velocity.z, direction.z * move_speed, acceleration * delta)
	body.rotation.y = lerp_angle(body.rotation.y, atan2(-direction.x, -direction.z), delta * 5.0)
