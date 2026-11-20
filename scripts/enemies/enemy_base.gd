class_name EnemyBase
extends CharacterBody3D

@export var enemy_size := 1.0
@export var health_multiplier := 1.0
@export var move_speed := 3.0

@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar/SubViewport/ProgressBar
@onready var visual: MeshInstance3D = $Visual

func _ready() -> void:
	add_to_group("enemies")
	health.set_max_health(health.max_health * health_multiplier, true)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	visual.scale = Vector3.ONE * enemy_size
	_on_health_changed(health.current_health, health.max_health)

func _on_health_changed(current: float, maximum: float) -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = maximum
		health_bar.value = current

func _on_died() -> void:
	queue_free()
