
class_name AnimationComponent
extends Node

## Controls the player's AnimationTree.
##
## Expected root states:
## Grounded - BlendSpace1D: Idle and Swagger Walk
## Strafe   - BlendSpace2D: forward, backward, left, right
## jump     - nested StateMachine
## land     - nested StateMachine
## flow     - nested StateMachine
##
## The AnimationTree should be assigned in the Inspector.
## The player body is supplied through initialize().

@export var animation_tree: AnimationTree
@export var enabled := true

var playback: AnimationNodeStateMachinePlayback
var body: CharacterBody3D

var locked := false
var flowing := false
var dash_active := false
var airborne := false
var landing := false


## Connects this component to the player and obtains the root playback.
func initialize(character: CharacterBody3D) -> void:
	body = character

	if animation_tree:
		animation_tree.active = true
		playback = animation_tree.get("parameters/playback")


## Updates ordinary movement animations.
## Grounded uses movement input intensity.
## Strafe uses actual velocity converted into the player's local direction.
func set_locomotion(input_vector: Vector2, _running: bool, is_locked: bool) -> void:
	if not enabled or animation_tree == null or playback == null:
		return

	locked = is_locked

	# These animations take priority over ordinary locomotion.
	if flowing or dash_active or airborne or landing:
		return

	if locked:
		_travel_if_needed(&"Strafe")

		if body:
			# Remove vertical velocity; Strafe only needs horizontal movement.
			var world_velocity := Vector3(body.velocity.x, 0.0, body.velocity.z)

			# Convert world movement into directions relative to the character.
			# Local forward is -Z, backward is +Z, left is -X, right is +X.
			var local_velocity := body.global_basis.inverse() * world_velocity

			# Normalize so the BlendSpace receives directional values between -1 and 1.
			var local_direction := Vector2(local_velocity.x, local_velocity.z).normalized()

			if world_velocity.length_squared() < 0.01:
				local_direction = Vector2.ZERO

			animation_tree.set(
				"parameters/Strafe/blend_position",
				local_direction
			)
	else:
		_travel_if_needed(&"Grounded")

		# Grounded BlendSpace1D: 0 = Idle, 1 = Swagger Walk.
		animation_tree.set(
			"parameters/Grounded/blend_position",
			clampf(input_vector.length(), 0.0, 1.0)
		)


## Only changes animation state when Flow actually starts or stops.
## This function is called every physics frame, so repeated identical
## values must not interrupt jumping, landing, or dash animations.
func set_flow(active: bool) -> void:
	if not enabled or playback == null:
		return

	# Ignore repeated calls with no change in Flow state.
	if flowing == active:
		return

	flowing = active

	if active:
		airborne = false
		landing = false
		_travel_if_needed(&"flow")
	else:
		# Only return to locomotion if no higher-priority action is active.
		if not dash_active and not airborne and not landing:
			_return_to_locomotion()
			
# Starts the dedicated dash animation.
# The dash state is a nested StateMachine, so its Start → Animation
# transition automatically begins the non-looping dash clip.
#
# is_air_dash tells us whether the dash began while airborne.
# We preserve that information so we can return to the jump animation
# after an air dash finishes.
func play_dash(is_air_dash: bool = false) -> void:
	if not enabled or playback == null:
		return

	dash_active = true
	airborne = is_air_dash
	landing = false

	# Travel through the root StateMachine so the Dash transition's
	# configured crossfade is used.
	playback.travel(&"dash")
	
# Called by DashComponent when the dash movement duration expires.
# Returns to the appropriate animation without interrupting Flow.
func finish_dash() -> void:
	dash_active = false

	if flowing:
		return

	if airborne:
	# Use the configured Dash → Jump crossfade after an air dash.
		playback.travel(&"jump")
	else:
		_return_to_locomotion()
## Enters the jump state through the AnimationTree transition.
func play_jump(is_double_jump: bool = false) -> void:
	if not enabled or playback == null or flowing or dash_active:
		return

	airborne = true
	playback.travel(&"jump")

## Returns to the appropriate locomotion state after landing.
func finish_jump() -> void:
	if not enabled or not airborne:
		return

	airborne = false
	_return_to_locomotion()

### Enters the landing state and prepares the landing animation.
#func play_land() -> void:
#	if not enabled or playback == null or flowing or dash_active:
#		return
#
#	airborne = false
#	landing = true
#
#	# Enter the root landing state.
#	playback.start(&"land", true)
#	
### Manually starts the landing animation, then waits for it to finish.
#func update_landing() -> void:
#	if not landing or animation_tree == null:
#		return
#
#	var land_playback := animation_tree.get("parameters/land/playback") as AnimationNodeStateMachinePlayback
#
#	if land_playback == null:
#		return
#
#	var current_state := land_playback.get_current_node()
#
#	# Start is the entry point. Explicitly enter the landing animation.
#	if current_state == &"Start":
#		land_playback.start(&"landing_mixamo_com", true)
#		return
#
#	# The animation's Auto transition brings us here when it finishes.
#	if current_state == &"End":
#		landing = false
#		_return_to_locomotion()
#		
## Preserved interface for future jump-charge visuals.
## The current root graph does not contain a charge blend parameter.
func set_jump_charge(_amount: float) -> void:
	pass


## Allows other scripts to request a root state.
func travel(state_name: StringName) -> void:
	_travel_if_needed(state_name)


## Returns to the appropriate locomotion state using the configured crossfade.
func _return_to_locomotion() -> void:
	if playback == null:
		return

	var target_state: StringName = &"Strafe" if locked else &"Grounded"
	playback.travel(target_state)
	
## Switches directly because the root transitions are code-driven.
func _travel_if_needed(state_name: StringName) -> void:
	if playback == null:
		return

	if playback.get_current_node() != state_name:
		playback.start(state_name, true)
