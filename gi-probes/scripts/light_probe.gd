extends Node3D

func _ready():
	add_to_group("light_probes")

@export var obj_list : Array[MeshInstance3D]
@export var min_dist : float

func assign_mats(sh):
	
	for obj in obj_list:
		var mat = obj.get_active_material(0).duplicate()
		obj.set_surface_override_material(0, mat)
		
		mat.set_shader_parameter("use_sh", true)
		mat.set_shader_parameter("sh", sh)

func debug_set(sh):
	var probe_mat = $SHBall.get_active_material(0).duplicate()
	$SHBall.material_override = probe_mat
	probe_mat.set_shader_parameter("sh", sh)
