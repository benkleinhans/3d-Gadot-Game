extends CharacterBody3D

@export_group("Input Actions")
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_forward := "move_forward"
@export var input_back := "move_back"
@export var input_jump := "jump"
@export var input_run := "run_toggle"
@export var input_flow := "flow_hold"
@export var input_dash := "dash"
@export var input_lock_on := "lock_on"
@export var input_melee := "melee_toggle"
@export var input_attack := "attack"
@export var input_launcher := "launcher"
@export var input_freefly := "freefly"

@onready var head: Node3D = $Head
@onready var camera_pivot: Node3D = $Head/CameraPivot
@onready var camera_rig: PlayerCamera = $Head/CameraPivot/CameraRig
@onready var camera: Camera3D = $Head/CameraPivot/CameraRig/SpringArm3D/Camera3D
@onready var collider: CollisionShape3D = $Collider
@onready var movement: MovementComponent = $Components/MovementComponent
@onready var look: LookComponent = $Components/LookComponent
@onready var health: HealthComponent = $Components/HealthComponent
@onready var jump: JumpComponent = $Components/JumpComponent
@onready var dash: DashComponent = $Components/DashComponent
@onready var flow: FlowComponent = $Components/FlowComponent
@onready var lock_on: LockOnComponent = $Components/LockOnComponent
@onready var combat: CombatComponent = $Components/CombatComponent
@onready var piercer: PiercerComponent = $Components/PiercerComponent
@onready var animation: AnimationComponent = $Components/AnimationComponent
@onready var checkpoint: CheckpointComponent = $Components/CheckpointComponent

var running := false
var freeflying := false
var freefly_speed := 18.0
var flow_was_active := false
var launcher_was_pressed := false

func _ready() -> void:
	movement.initialize(self, camera)
	look.initialize(self, camera_pivot)
	animation.initialize(self)

	jump.initialize(self)
	jump.jump_started.connect(animation.play_jump)

	dash.initialize(self, movement)
	dash.dash_started.connect(animation.play_dash)
	dash.dash_finished.connect(animation.finish_dash)
	
	flow.initialize(self, movement)
	lock_on.initialize(self)
	checkpoint.initialize(self, health)
	health.died.connect(_on_died)
	lock_on.target_changed.connect(_on_lock_target_changed)
	lock_on.lock_cleared.connect(_on_lock_cleared)
	flow.flow_started.connect(_on_flow_started)
	flow.flow_ended.connect(_on_flow_ended)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look.handle_mouse_motion(event.relative)

func _physics_process(delta: float) -> void:
	if health.is_dead:
		return
		
	if Input.is_action_just_pressed(input_freefly):
		freeflying = not freeflying
		velocity = Vector3.ZERO
		collider.set_deferred("disabled", freeflying)
	
	var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
	var look_axis := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if look_axis.length() > 0.15:
		look.handle_stick_look(look_axis, delta)

	if Input.is_action_just_pressed(input_run):
		if flow.flowing:
			flow.disable_flow()
			running = true
		else:
			running = not running

	flow.set_hold_active(Input.is_action_pressed(input_flow))
	flow.tick(delta)

	if Input.is_action_just_pressed(input_lock_on):
		lock_on.toggle_lock()
	lock_on.update_lock(delta)
	camera_rig.set_lock_target(lock_on.target)

	if Input.is_action_just_pressed(input_melee):
		combat.toggle_melee()
	if Input.is_action_just_pressed(input_launcher):
		piercer.toggle_launcher()
		camera_rig.launcher_view = piercer.launcher_mode
	piercer.tick(delta, Input.is_action_pressed(input_launcher))
	if Input.is_action_just_pressed(input_attack):
		if piercer.launcher_mode:
			piercer.fire()
		else:
			combat.request_attack(not is_on_floor(), running, flow.flowing)

	if Input.is_action_just_pressed(input_dash) and not flow.flowing:
		dash.try_dash(input_dir)
	dash.tick(delta)
	combat.tick(delta)

	if Input.is_action_just_pressed(input_jump) and not flow.flowing and not dash.is_dashing:
		jump.begin_charge()
	if Input.is_action_just_released(input_jump) and jump.charging:
		jump.release_charge()
	if jump.charging:
		jump.update_charge(delta)
	jump.reset_on_floor()

	if freeflying:
		_process_freefly(input_dir, delta)
		move_and_slide()
		return

	if flow.flowing:
		jump.cancel_charge()
		flow.apply_flow(input_dir, delta)
	elif dash.is_dashing:
		if not dash.use_gravity_during_dash:
			pass
	else:
		movement.apply_gravity(delta)
		jump.apply_fall_gravity(delta)
		movement.update_movement(
		input_dir,
		delta,
		running,
		false,
		lock_on.target == null,
		lock_on.target != null
		)
		
	if lock_on.target != null:
		# Lock-on keeps the body facing the target; input remains camera-relative.
		pass
		
	# Update locomotion and special movement animations.
	animation.set_locomotion(input_dir, running, lock_on.target != null)
	animation.set_flow(flow.flowing)
	animation.set_jump_charge(jump.get_charge_ratio() if jump.charging else 0.0)

	# Remember whether the player was grounded before moving.
	var was_on_floor := is_on_floor()

	look.sync_camera_rotation()
	move_and_slide()

	# Return to locomotion when the player touches the ground.
	if not was_on_floor and is_on_floor():
		animation.finish_jump()

func _process_freefly(input_dir: Vector2, delta: float) -> void:
	var direction := movement.get_camera_relative_direction(input_dir)
	var vertical := 0.0
	if Input.is_key_pressed(KEY_E):
		vertical += 1.0
	if Input.is_key_pressed(KEY_Q):
		vertical -= 1.0
	velocity = (direction + Vector3.UP * vertical).normalized() * freefly_speed

func _on_lock_target_changed(target: Node3D) -> void:
	camera_rig.set_lock_target(target)

func _on_lock_cleared() -> void:
	camera_rig.clear_lock_target()

func _on_flow_started() -> void:
	jump.cancel_charge()
	dash.is_dashing = false
	flow_was_active = true

func _on_flow_ended() -> void:
	running = true
	flow_was_active = false

func _on_died() -> void:
	velocity = Vector3.ZERO
	movement.can_move = false
