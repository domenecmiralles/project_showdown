extends Interactable
class_name InteractableSound

@export var sound: AudioStream  # Assign a default sound per interactable in the Inspector
@onready var audio_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

func _ready():
	add_child(audio_player)  # Dynamically add an AudioStreamPlayer3D
	audio_player.finished.connect(_on_audio_finished)  # Connect the signal via code

func interact(_player: CharacterBody3D):
	super.interact(_player)
	if audio_player.playing:
		return
	if sound:
		audio_player.stream = sound
		audio_player.play()

# Function to be called when the sound finishes
func _on_audio_finished():
	player.current_camera.set_current(true)
	player.change_state(player.State.IDLE)

