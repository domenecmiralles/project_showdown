extends Node3D
class_name CameraSetup

@onready var player: CharacterBody3D
@export var cam_area: Area3D
@export var camera: Camera3D

@export var look_at_player: bool = false

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	else:
		print("Player node not found")

func _process(_delta):
	if player:
		if look_at_player:
			camera.look_at(player.global_transform.origin, Vector3.UP)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		print("Player entered camera area")
		camera.set_current(true)
		player.current_camera = camera
