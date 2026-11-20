class_name LockOnComponent
extends Node

signal target_changed(target: Node3D)
signal lock_cleared

@export var max_lock_distance := 30.0
@export var turn_speed := 9.0
@export var target_group := "enemies"

var body: CharacterBody3D
var target: Node3D

func initialize(character: CharacterBody3D) -> void:
	body = character

func toggle_lock() -> void:
	if is_instance_valid(target):
		clear_lock()
	else:
		lock_nearest()

func lock_nearest() -> void:
	if body == null:
		return
	var nearest: Node3D
	var nearest_distance := max_lock_distance
	for candidate in get_tree().get_nodes_in_group(target_group):
		if not candidate is Node3D or candidate == body:
			continue
		var distance := body.global_position.distance_to(candidate.global_position)
		if distance < nearest_distance and not _candidate_dead(candidate):
			nearest = candidate
			nearest_distance = distance
	if nearest:
		target = nearest
		target_changed.emit(target)

func update_lock(delta: float) -> void:
	if not is_instance_valid(target):
		if target != null:
			clear_lock()
		return
	var direction := target.global_position - body.global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		var desired := atan2(-direction.x, -direction.z)
		body.rotation.y = lerp_angle(body.rotation.y, desired, turn_speed * delta)

func clear_lock() -> void:
	target = null
	lock_cleared.emit()

func _candidate_dead(candidate: Node) -> bool:
	var health := candidate.get_node_or_null("HealthComponent")
	return health != null and health.is_dead
