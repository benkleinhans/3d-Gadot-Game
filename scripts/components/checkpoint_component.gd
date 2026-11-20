class_name CheckpointComponent
extends Node

signal checkpoint_changed(position: Vector3)
signal respawned

@export var respawn_delay := 1.0
var body: CharacterBody3D
var health: HealthComponent
var checkpoint_transform := Transform3D.IDENTITY
var has_checkpoint := false

func initialize(character: CharacterBody3D, health_component: HealthComponent) -> void:
	body = character
	health = health_component
	if body:
		checkpoint_transform = body.global_transform
		has_checkpoint = true
	if health:
		health.died.connect(_on_player_died)

func set_checkpoint(marker: Node3D) -> void:
	if marker == null:
		return
	checkpoint_transform = marker.global_transform
	has_checkpoint = true
	checkpoint_changed.emit(marker.global_position)

func set_checkpoint_transform(value: Transform3D) -> void:
	checkpoint_transform = value
	has_checkpoint = true
	checkpoint_changed.emit(value.origin)

func _on_player_died() -> void:
	_respawn.call_deferred()

func _respawn() -> void:
	if body == null:
		return
	await get_tree().create_timer(respawn_delay).timeout
	body.global_transform = checkpoint_transform if has_checkpoint else Transform3D.IDENTITY
	body.velocity = Vector3.ZERO
	if health:
		health.reset_health()
	respawned.emit()
