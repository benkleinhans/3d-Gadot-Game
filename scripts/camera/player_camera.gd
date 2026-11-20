class_name PlayerCamera
extends Node3D

@export var normal_fov := 75.0
@export var launcher_fov := 55.0
@export var fov_smoothing := 7.0
@export var lock_target_height := 1.2

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var lock_target: Node3D
var launcher_view := false

func _process(delta: float) -> void:
	if camera:
		var target_fov := launcher_fov if launcher_view else normal_fov
		camera.fov = lerpf(camera.fov, target_fov, fov_smoothing * delta)

func set_lock_target(target: Node3D) -> void:
	lock_target = target

func clear_lock_target() -> void:
	lock_target = null
