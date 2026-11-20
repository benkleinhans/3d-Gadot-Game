class_name EnemyCombatComponent
extends Node

signal attack_started(target: Node3D)
@export var damage := 10.0
@export var attack_range := 2.0
@export var attack_cooldown := 1.5
var cooldown_left := 0.0

func tick(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)

func try_attack(owner_body: Node3D, target: Node3D) -> bool:
	if cooldown_left > 0.0 or owner_body == null or not is_instance_valid(target):
		return false
	if owner_body.global_position.distance_to(target.global_position) > attack_range:
		return false
	var target_health := target.get_node_or_null("Components/HealthComponent")
	if target_health == null:
		target_health = target.get_node_or_null("HealthComponent")
	if target_health:
		target_health.take_damage(damage)
		cooldown_left = attack_cooldown
		attack_started.emit(target)
		return true
	return false
