extends RayCast3D

@onready var player: CharacterBody3D = get_parent()

# Check for interactions with InteractArea nodes
func check_interaction():
    if self.is_colliding():
        var hit = self.get_collider()
        return hit