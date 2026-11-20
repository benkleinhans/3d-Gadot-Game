class_name EnemyStateMachine
extends Node

enum State { IDLE, ROAM, DETECT, CHASE, ATTACK, DODGE, DASH, DEAD }
var current_state: State = State.IDLE

signal state_changed(previous: State, current: State)

func transition_to(next_state: State) -> void:
	if current_state == next_state:
		return
	var previous := current_state
	current_state = next_state
	state_changed.emit(previous, current_state)
