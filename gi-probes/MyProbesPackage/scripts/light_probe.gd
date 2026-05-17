@tool
extends Node3D

func _ready():
	add_to_group("light_probes")


@export var show_debug : bool:
	set(value):
		show_debug = value
		$SHBall.visible = value

func min_dist() -> float:
	return min(scale.x, scale.y, scale.z)

func debug_set(sh):
	var probe_mat = $SHBall.get_active_material(0).duplicate()
	$SHBall.material_override = probe_mat
	probe_mat.set_shader_parameter("sh", sh)
