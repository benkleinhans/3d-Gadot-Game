class_name HealthComponent
extends Node

signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float, current_health: float)
signal healed(amount: float, current_health: float)
signal died

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
@export_range(0.0, 10000.0, 1.0) var starting_health: float = 100.0

var current_health: float = 100.0
var is_dead: bool = false

func _ready() -> void:
	current_health = clampf(starting_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount, current_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	var before := current_health
	current_health = minf(current_health + amount, max_health)
	healed.emit(current_health - before, current_health)
	health_changed.emit(current_health, max_health)

func set_max_health(value: float, refill: bool = false) -> void:
	if value <= 0.0:
		return
	max_health = value
	current_health = max_health if refill else minf(current_health, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()

func reset_health() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)

func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit()
