extends CharacterBody3D
class_name Player


@onready var camera_3d: Camera3D = $Camera3D
@onready var animation_player: AnimationPlayer = $Camera3D/AnimationPlayer
@onready var gpu_particles_3d: GPUParticles3D = $Camera3D/Pistol/GPUParticles3D
@onready var sci_fi_pistol_body: MeshInstance3D = $"Camera3D/Pistol/Sci-fi Pistol_Body"
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D
@onready var progress_bar: ProgressBar = $Camera3D/CanvasLayer/ProgressBar


var health := 3.0

const SPEED := 10.0
const JUMP_VELOCITY := 10.0
var canMove : bool = true
var gravity := 20.0

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	pass

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	sci_fi_pistol_body.set_surface_override_material(0, sci_fi_pistol_body.get_active_material(0).duplicate()) 
	sci_fi_pistol_body.get_active_material(0).set("use_fov_override", true)
	sci_fi_pistol_body.get_active_material(0).set("use_z_clip_scale", true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_3d.current = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("quit"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			canMove = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			canMove = true

	if event is InputEventMouseMotion and canMove:
		rotate_y(-event.relative.x * .005)
		camera_3d.rotate_x(-event.relative.y * .005)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, -PI/2, PI/2)
		pass
	if event.is_action_pressed("shoot") \
		and animation_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if ray_cast_3d.is_colliding():
			var hit_player := ray_cast_3d.get_collider()
			if hit_player.has_method("revieve_damage"):
				hit_player.revieve_damage.rpc_id(hit_player.get_multiplayer_authority())
			pass
		

@rpc("call_local")
func play_shoot_effects() -> void:
	animation_player.stop()
	animation_player.play("shoot")
	gpu_particles_3d.restart()
	gpu_particles_3d.emitting = true
	pass
	
@rpc("any_peer")
func revieve_damage():
	health -= 1
	updateUI()
	if health <= 0:
		health = 3
		position = Vector3.ZERO
		updateUI()
		
func updateUI():
	progress_bar.value = health
	pass



func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward") if canMove else Vector2.ZERO
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if animation_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		animation_player.play("move")
	else:
		animation_player.play("idle")

	move_and_slide()
