extends CharacterBody3D  # Player is a CharacterBody3D, allowing movement with physics

signal state_changed(new_state)  # Signal emitted when the player's state changes

@onready var interact_ray: RayCast3D = $InteractRay  # Raycast to check for interactable objects
@onready var anim: AnimationPlayer = $Palmer/AnimationPlayer  # Animation player for player animations
@onready var player_cam: Camera3D = $Camera3D
@export var current_camera: Camera3D  # Stores the current active camera

var speed = 3  # Movement speed
var target_position: Vector3  # Target position for movement
var gravity: float = 9.8  # Gravity value

# Enum defining player states
enum State { IDLE, WALKING, INTERACTING }
var current_state = State.IDLE 

func _ready() -> void:
	var cameras = get_tree().get_nodes_in_group("Camera")
	for camera in cameras:
		camera.get_node("Camera3D").get_node("PSXShader").visible = true 
	current_camera.set_current(true) 

func _input(_event: InputEvent) -> void:
	# if click on interactable next to it, interact; otherwise move if the clicked position is part of the map
	if Input.is_action_just_pressed("mouse_left_click"):
		if current_state == State.WALKING or current_state == State.IDLE:
			var move_ray_result = raycast_to_mouse_position()  # Perform raycast to see where the player clicked
			if move_ray_result.has('collider') and move_ray_result.collider is Interactable:
				if check_interaction():
					return
			if move_ray_result.has("position"):  # If a valid position was found
				target_position = Vector3(move_ray_result.position.x, global_position.y, move_ray_result.position.z) 
				change_state(State.WALKING) 

func _process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			pass  # Do nothing while idle
		State.WALKING:
			move_to_point(_delta)  # Move the player
		State.INTERACTING:
			pass  # interactables release the player on specific conditions

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0  # Reset vertical velocity when on the floor
	else:
		velocity.y -= gravity * delta  # Apply gravity when not on the floor

func move_to_point(_delta):
	if global_position.distance_to(target_position) < 0.1: 
		stop_movement()
		anim.play("idle")  # Play idle animation
		return
	anim.play("walking")  # Play walk animation
	#double the animation speed:
	anim.speed_scale = 3

	var direction = global_position.direction_to(target_position)  # Get movement direction
	face_direction(target_position)  # Rotate the player toward the movement direction

	# Move character
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

	

func stop_movement():
	change_state(State.IDLE)

func face_direction(direction: Vector3):
	if not global_position.is_equal_approx(direction):  # ✅ Check if direction is different
		look_at(Vector3(direction.x, global_position.y, direction.z), Vector3.UP)

func raycast_to_mouse_position():
	var mouse_position = get_viewport().get_mouse_position()  # Get the mouse position on screen
	var ray_length = 500  # Max distance of the ray
	var from = current_camera.project_ray_origin(mouse_position)  # Start point of ray (camera position)
	var to = from + current_camera.project_ray_normal(mouse_position) * ray_length  # End point of the ray

	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.exclude = [self]  # Ignore the player itself
	ray_query.from = from
	ray_query.to = to

	return space.intersect_ray(ray_query)  # Return raycast result

func check_interaction():
	var interact_ray_result = interact_ray.check_interaction()
	if interact_ray_result != null and interact_ray_result is Interactable:
		interact_ray_result.interact(self)  # Call the interact function on the interactable object
		return true
	return false

func change_state(new_state):
	current_state = new_state
	emit_signal("state_changed", current_state)
