extends Node

func _ready() -> void:
	get_parent().add_to_group("update_materials")

func get_mat_pos() -> Vector3:
	return get_parent().global_position
