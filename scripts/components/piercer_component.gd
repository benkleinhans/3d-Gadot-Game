class_name PiercerComponent
extends Node

signal launcher_mode_changed(active: bool)
signal shot_fired(dual: bool)

@export var single_shot_cooldown := 60.0
@export var melee_hit_cooldown_reduction := 2.0
@export var dual_charge_seconds := 5.0
@export var projectile_scene: PackedScene

var launcher_mode := false
var dual_mode := false
var dual_hold_time := 0.0
var cooldown_left := 0.0
var charging_dual := false

func tick(delta: float, launcher_held: bool) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if launcher_mode and launcher_held:
		charging_dual = true
		dual_hold_time += delta
		if dual_hold_time >= dual_charge_seconds:
			dual_mode = true
	else:
		charging_dual = false
		dual_hold_time = 0.0

func toggle_launcher() -> void:
	launcher_mode = not launcher_mode
	if not launcher_mode:
		dual_mode = false
	launcher_mode_changed.emit(launcher_mode)

func fire() -> bool:
	if not launcher_mode or cooldown_left > 0.0:
		return false
	cooldown_left = single_shot_cooldown
	shot_fired.emit(dual_mode)
	dual_mode = false
	return true

func register_melee_hit() -> void:
	cooldown_left = maxf(cooldown_left - melee_hit_cooldown_reduction, 0.0)
