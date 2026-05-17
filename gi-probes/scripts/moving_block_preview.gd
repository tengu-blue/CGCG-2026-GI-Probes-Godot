extends MeshInstance3D

# Move the block around
# Update it's harmonics


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	LightProbesController.update_object(self)
