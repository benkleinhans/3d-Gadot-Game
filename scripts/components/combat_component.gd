class_name CombatComponent
extends Node

signal melee_mode_changed(active: bool)
signal attack_requested(attack_type: StringName)

@export var melee_enabled := true
var melee_mode := false
var attack_cooldown := 0.35
var attack_timer := 0.0

func toggle_melee() -> void:
	melee_mode = not melee_mode
	melee_mode_changed.emit(melee_mode)

func request_attack(in_air: bool, running: bool, flowing: bool) -> void:
	if not melee_enabled or not melee_mode or attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	var kind: StringName = &"air_slash" if in_air else (&"flow_attack" if flowing else (&"run_stab" if running else &"backhand_slash"))
	attack_requested.emit(kind)

func tick(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
