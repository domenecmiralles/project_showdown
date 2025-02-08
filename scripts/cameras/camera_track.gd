extends CameraSetup
class_name CameraTrack

@export var target: Node3D
@export var speed: float = 5.0

@onready var path_follow: PathFollow3D = $TrackNode/Path3D/PathFollow3D
@onready var path: Path3D = $TrackNode/Path3D
@onready var track_node: Node3D = $TrackNode

func _process(delta):
	if target:
		var curve: Curve3D = path.curve
		if curve:
			# Convert player position to the local space of Path3D
			var target_position = path.to_local(target.global_transform.origin)

			# Get closest offset along the path
			var target_progress = curve.get_closest_offset(target_position)

			# Ensure progress stays within valid limits
			target_progress = clamp(target_progress, 0.0, curve.get_baked_length())

			# Move the camera smoothly
			path_follow.progress = move_toward(path_follow.progress, target_progress, speed * delta)
