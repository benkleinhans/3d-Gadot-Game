class_name EnemyDetectionComponent
extends Node

@export var detection_range := 15.0
@export var player_group := "player"
var detected_player: Node3D

func scan(origin: Node3D) -> Node3D:
	detected_player = null
	if origin == null:
		return null
	for candidate in get_tree().get_nodes_in_group(player_group):
		if candidate is Node3D and origin.global_position.distance_to(candidate.global_position) <= detection_range:
			detected_player = candidate
			break
	return detected_player
