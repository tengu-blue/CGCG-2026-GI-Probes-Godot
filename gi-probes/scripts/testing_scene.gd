extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: load from file
	# LightProbesController.update_probes()
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("update_probes"):
		LightProbesController.update_probes()
	elif Input.is_action_just_pressed("toggle_probes"):
		LightProbesController.toggle()
