extends CharacterBody3D  # Player is a CharacterBody3D, allowing movement with physics

signal state_changed(new_state)  # Signal emitted when the player's state changes

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D  # Navigation system for movement
@onready var interact_ray: RayCast3D = $InteractRay  # Raycast to check for interactable objects

@export var current_camera: Camera3D  # Stores the current active camera

var speed = 5  # Movement speed
var stuck_timer = 0.0  # Timer to detect if the player is stuck
var last_position: Vector3  # Stores the last position for movement checks

# Enum defining player states
enum State { IDLE, WALKING }
var current_state = State.IDLE  # Start in the IDLE state

func _ready() -> void:
	"""
	Runs when the node enters the scene.
	Initializes the camera and enables the shader effect on all cameras in the group.
	"""
	var cameras = get_tree().get_nodes_in_group("Camera")
	for camera in cameras:
		camera.get_node("Camera3D").get_node("PSXShader").visible = true  # Enable visual effect for all cameras
	current_camera.set_current(true)  # Set the current camera

func _input(_event: InputEvent) -> void:
	"""
	Handles player input.
	If the player left-clicks, determine whether to interact or move.
	"""
	if Input.is_action_just_pressed("mouse_left_click"):
		if current_state == State.WALKING or current_state == State.IDLE:
			var move_ray_result = raycast_to_mouse_position()  # Perform raycast to see where the player clicked
			print(move_ray_result)
			if move_ray_result.has("position"):  # If a valid position was found
				nav_agent.target_position = move_ray_result.position  # Set navigation target
				change_state(State.WALKING)  # Switch to walking state
				last_position = global_position  # Store current position for stuck detection
				stuck_timer = 0.0  # Reset stuck timer

func _process(_delta: float) -> void:
	"""
	Runs every frame.
	Calls movement logic when the player is in the WALKING state.
	"""
	match current_state:
		State.IDLE:
			pass  # Do nothing while idle
		State.WALKING:
			move_to_point(_delta)  # Move the player

func move_to_point(delta):
	"""
	Moves the player toward the target position using the NavigationAgent3D.
	Stops if the path is finished or if the player is stuck.
	"""
	if nav_agent.is_navigation_finished():  # If the player has reached the destination
		check_interaction()  # Attempt interaction if applicable
		stop_movement()  # Stop movement
		return

	var target_position = nav_agent.get_next_path_position()  # Get the next waypoint
	var direction = global_position.direction_to(target_position)  # Get movement direction
	face_direction(nav_agent.target_position)  # Rotate the player toward the movement direction

	# Move character
	velocity = direction * speed
	move_and_slide()

	# **🔹 Stuck Detection: Check if player has moved**
	stuck_timer += delta
	if stuck_timer > 0.1:  # Every 0.5 seconds, check if the player is moving
		if global_position.distance_to(last_position) < 0.1:  # If barely moved
			check_interaction()  # Attempt interaction if applicable
			stop_movement()
			return
		last_position = global_position  # Update position for next check
		stuck_timer = 0.0  # Reset timer

func stop_movement():
	"""
	Stops the player’s movement and resets to IDLE state.
	"""
	change_state(State.IDLE)

func face_direction(direction):
	"""
	Rotates the player to face the given direction.
	"""
	look_at(Vector3(direction.x, global_position.y, direction.z), Vector3.UP)

func raycast_to_mouse_position():
	"""
	Performs a raycast from the camera toward the mouse position.
	Returns the first object hit (if any).
	"""
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
	"""
	Checks if the player's interaction ray is colliding with an interactable object.
	If so, triggers the interaction.
	"""
	var interact_ray_result = interact_ray.check_interaction()
	if interact_ray_result != null and interact_ray_result is Interactable:
		interact_ray_result.interact(self)  # Call the interact function on the interactable object
		return true
	return false

func change_state(new_state):
	current_state = new_state
	emit_signal("state_changed", current_state)
