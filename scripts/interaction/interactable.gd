extends Node3D
class_name Interactable

@export var camera: Camera3D

var player: CharacterBody3D

func interact(_player: CharacterBody3D):
	player = _player
	player.look_at(Vector3(self.global_transform.origin.x, player.global_position.y, self.global_transform.origin.z), Vector3.UP)
	player.change_state(player.State.INTERACTING)
	if camera:
		camera.set_current(true)
	else:
		player.player_cam.set_current(true)

