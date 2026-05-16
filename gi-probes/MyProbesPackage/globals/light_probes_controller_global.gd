extends Node

@export var prober : Prober
var all_probes : TetrahedralInterpolator

func _ready() -> void:
	all_probes = TetrahedralInterpolator.new()


# TODO: proper kd closest find
func get_closest_probe(pos : Vector3):	
	return all_probes.query(pos)


var t := false
func toggle():
	var materials = get_tree().get_nodes_in_group("update_materials")
	for obj in materials:
		var mat = obj.get_active_material(0)
		mat.set_shader_parameter("use_sh", t)
	
	t = not t

# on update_probes()
func update_probes():
	# find all probes
	var probes = get_tree().get_nodes_in_group("light_probes")
	var sh_harmonics = []
	
	# compute the harmonics for each probes
	for probe in probes:
		var sh = await prober.capture(probe.global_position, probe.min_dist)
		sh_harmonics.push_back(sh)
	
		# debug test
		# probe.debug_set(sh)
	
	# store the harmonics and positions
	var positions: Array[Vector3] = []

	for probe in probes:
		positions.append(probe.global_position)
	
	all_probes.build(positions, sh_harmonics)
	
	
	
	# only set the values to all, once all computed	
	# for i in range(len(probes)):
	#	probes[i].assign_mats(sh_harmonics[i])
	
	# find all materials with the custom shader
	# set their sh based on the closest probe
	var materials = get_tree().get_nodes_in_group("update_materials")
	for obj in materials:
		var mat = obj.get_active_material(0).duplicate()
		obj.set_surface_override_material(0, mat)
		
		mat.set_shader_parameter("use_sh", true)
		var closest = get_closest_probe(obj.global_position) 
		mat.set_shader_parameter("sh", closest)
